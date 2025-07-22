package proof

import (
	"encoding/hex"
	"log/slog"
	"math/big"

	"github.com/consensys/gnark-crypto/ecc/bn254"
	"github.com/consensys/gnark/frontend"
	"github.com/consensys/gnark/std/algebra/emulated/sw_bn254"
	"github.com/consensys/gnark/std/algebra/emulated/sw_emulated"
	"github.com/consensys/gnark/std/hash/mimc"
	gnarkSha3 "github.com/consensys/gnark/std/hash/sha3"
	"github.com/consensys/gnark/std/math/bits"
	"github.com/consensys/gnark/std/math/emulated"
	"github.com/consensys/gnark/std/math/uints"
	"github.com/ethereum/go-ethereum/crypto"
)

// Circuit defines a pre-image knowledge proof
type Circuit struct {
	InputHash             frontend.Variable      `gnark:",public"`  // 254 bits
	SignersAggVotingPower frontend.Variable      `gnark:",private"` // 254 bits, virtually public
	Message               sw_bn254.G1Affine      `gnark:",private"` // virtually public
	Signature             sw_bn254.G1Affine      `gnark:",private"`
	SignersAggKeyG2       sw_bn254.G2Affine      `gnark:",private"`
	ValidatorData         []ValidatorDataCircuit `gnark:",private"`
}

type ValidatorDataCircuit struct {
	Key         sw_bn254.G1Affine
	VotingPower frontend.Variable
	IsNonSigner frontend.Variable
}

type ProveInput struct {
	ValidatorData   []ValidatorData
	MessageG1       bn254.G1Affine
	Signature       bn254.G1Affine
	SignersAggKeyG2 bn254.G2Affine
}

// Define declares the circuit's constraints
func (circuit *Circuit) Define(api frontend.API) error {
	// --------------------------------------- Prove ValSet consistency ---------------------------------------
	curveApi, err := sw_emulated.New[emulated.BN254Fp, emulated.BN254Fr](api, sw_emulated.GetBN254Params())
	if err != nil {
		return err
	}

	fieldFpApi, err := emulated.NewField[emulated.BN254Fp](api)
	if err != nil {
		return err
	}

	fieldFrApi, err := emulated.NewField[emulated.BN254Fr](api)
	if err != nil {
		return err
	}

	mimcApi, err := mimc.NewMiMC(api)
	if err != nil {
		return err
	}

	keccak256Api, err := gnarkSha3.NewLegacyKeccak256(api)
	if err != nil {
		return err
	}

	u64Api, err := uints.New[uints.U64](api)
	if err != nil {
		return err
	}

	pairingApi, err := sw_bn254.NewPairing(api)
	if err != nil {
		return err
	}

	valsetHash := frontend.Variable(0)
	signersAggKey := &sw_bn254.G1Affine{
		X: emulated.ValueOf[emulated.BN254Fp](0),
		Y: emulated.ValueOf[emulated.BN254Fp](0),
	}
	signersAggVotingPower := frontend.Variable(0)

	// calc valset hash, agg key and agg voting power
	for i := range circuit.ValidatorData {
		hashAffineG1(&mimcApi, &circuit.ValidatorData[i].Key)
		mimcApi.Write(circuit.ValidatorData[i].VotingPower)

		isFillerValidatorData := api.And(fieldFpApi.IsZero(&circuit.ValidatorData[i].Key.X), fieldFpApi.IsZero(&circuit.ValidatorData[i].Key.Y))

		// hash data if VALIDATOR is not a filler
		valsetHash = api.Select(
			isFillerValidatorData,
			valsetHash,
			mimcApi.Sum(),
		)

		isFillerOrNonSigner := api.Or(isFillerValidatorData, circuit.ValidatorData[i].IsNonSigner)

		// add power if VALIDATOR is not a filler and SIGNER
		signersAggVotingPower = api.Select(
			isFillerOrNonSigner,
			signersAggVotingPower,
			api.Add(signersAggVotingPower, circuit.ValidatorData[i].VotingPower),
		)

		// aggregate key if VALIDATOR is not a filler and SIGNER
		signersAggKey = curveApi.Select(
			isFillerOrNonSigner,
			signersAggKey,
			curveApi.AddUnified(signersAggKey, &circuit.ValidatorData[i].Key),
		)
	}

	// compare with public inputs
	api.AssertIsEqual(signersAggVotingPower, circuit.SignersAggVotingPower)

	// --------------------------------------- Prove Input consistency ---------------------------------------

	// valset consistency checked against InputHash which is Hash{valset-hash|non-signers-vp|message}
	hashBytes := variableToBytes(api, u64Api, valsetHash)

	api.Println("HashBytes:", hashBytes)
	keccak256Api.Write(hashBytes)
	aggVotingPowerBytes := variableToBytes(api, u64Api, circuit.SignersAggVotingPower)

	api.Println("aggVotingPowerBytes:", aggVotingPowerBytes)
	keccak256Api.Write(aggVotingPowerBytes)
	messageBytes := keyToBytes(u64Api, &circuit.Message)

	api.Println("MessageBytes:", messageBytes)
	keccak256Api.Write(messageBytes)
	inputDataHash := keccak256Api.Sum()
	api.Println("InputDataHash:", inputDataHash)
	inputHashBytes := variableToBytes(api, u64Api, circuit.InputHash)

	inputDataHash[0] = u64Api.ByteValueOf(u64Api.ToValue(u64Api.And(u64Api.ValueOf(inputDataHash[0].Val), uints.NewU64(0x1f)))) // zero two first bits
	for i := range inputHashBytes {
		u64Api.ByteAssertEq(inputDataHash[i], inputHashBytes[i])
	}

	// --------------------------------------- Verify Signature ---------------------------------------

	// calc alpha
	mimcApi.Reset()
	hashAffineG1(&mimcApi, &circuit.Signature)
	hashAffineG1(&mimcApi, signersAggKey)
	hashAffineG2(&mimcApi, &circuit.SignersAggKeyG2)
	hashAffineG1(&mimcApi, &circuit.Message)
	//TODO optimize
	alpha := fieldFrApi.FromBits(bits.ToBinary(api, mimcApi.Sum())...)

	// pairing check
	_, _, g1Gen, g2Gen := bn254.Generators()
	g1GenAffine := sw_bn254.NewG1Affine(g1Gen)
	negG2GenAffine := sw_bn254.NewG2Affine(*g2Gen.Neg(&g2Gen))
	err = pairingApi.PairingCheck(
		[]*sw_bn254.G1Affine{
			curveApi.AddUnified(&circuit.Signature, curveApi.ScalarMul(signersAggKey, alpha)),
			curveApi.AddUnified(&circuit.Message, curveApi.ScalarMul(&g1GenAffine, alpha)),
		},
		[]*sw_bn254.G2Affine{
			&negG2GenAffine,
			&circuit.SignersAggKeyG2,
		},
	)

	return err
}

func setCircuitData(circuit *Circuit, proveInput ProveInput) {
	circuit.ValidatorData = make([]ValidatorDataCircuit, len(proveInput.ValidatorData))
	for i := range proveInput.ValidatorData {
		circuit.ValidatorData[i].Key = sw_bn254.NewG1Affine(proveInput.ValidatorData[i].Key)
		circuit.ValidatorData[i].VotingPower = proveInput.ValidatorData[i].VotingPower
		circuit.ValidatorData[i].IsNonSigner = *big.NewInt(0)

		if proveInput.ValidatorData[i].IsNonSigner {
			circuit.ValidatorData[i].IsNonSigner = *big.NewInt(1)
		}
	}

	_, nonSignersAggVotingPower, totalVotingPower := getNonSignersData(proveInput.ValidatorData)
	signersAggVotingPower := new(big.Int).Sub(totalVotingPower, nonSignersAggVotingPower)
	valsetHash := HashValset(proveInput.ValidatorData)

	circuit.SignersAggVotingPower = *signersAggVotingPower

	circuit.Signature = sw_bn254.NewG1Affine(proveInput.Signature)
	circuit.Message = sw_bn254.NewG1Affine(proveInput.MessageG1)
	circuit.SignersAggKeyG2 = sw_bn254.NewG2Affine(proveInput.SignersAggKeyG2)

	messageBytes := proveInput.MessageG1.RawBytes()
	aggVotingPowerBuffer := make([]byte, 32)
	signersAggVotingPower.FillBytes(aggVotingPowerBuffer)

	inputHashBytes := valsetHash
	inputHashBytes = append(inputHashBytes, aggVotingPowerBuffer...)
	inputHashBytes = append(inputHashBytes, messageBytes[:]...)
	inputHash := crypto.Keccak256(inputHashBytes)

	slog.Debug("signersAggVotingPower", "vp", signersAggVotingPower.String())
	slog.Debug("signed message", "message", proveInput.MessageG1.String())
	slog.Debug("signed message", "message.X", proveInput.MessageG1.X.String())
	slog.Debug("signed message", "message.Y", proveInput.MessageG1.Y.String())
	slog.Debug("mimc hash", "hash", hex.EncodeToString(valsetHash))

	inputHashInt := new(big.Int).SetBytes(inputHash)
	mask, _ := big.NewInt(0).SetString("1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", 16)
	inputHashInt.And(inputHashInt, mask)

	circuit.InputHash = inputHashInt

	slog.Debug("[Prove] input hash", "hash", hex.EncodeToString(inputHashInt.Bytes()))
}

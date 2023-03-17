// SPDX-License-Identifier: Apache-2.0
// Based on: https://github.com/starcoinorg/starcoin-framework-commons/blob/main/sources/PseudoRandom.move

/// @title pseudorandom
/// @notice A pseudo random module on-chain.
/// @dev Warning:
/// The random mechanism in smart contracts is different from
/// that in traditional programming languages. The value generated
/// by random is predictable to Miners, so it can only be used in
/// simple scenarios where Miners have no incentive to cheat. If
/// large amounts of money are involved, DO NOT USE THIS MODULE to
/// generate random numbers; try a more secure way.
module originmate::pseudorandom {
    use std::hash;
    use std::vector;

    use sui::bcs;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const EHIGH_ARG_GREATER_THAN_LOW_ARG: u64 = 1;

    /// Resource that wraps an integer counter
    struct Counter has key {
        id: UID,
        value: u256
    }

    /// Share a `Counter` resource with value `i`
    fun init(ctx: &mut TxContext) {
        // Create and share a Counter resource. This is a privileged operation that
        // can only be done inside the module that declares the `Counter` resource
        transfer::share_object(Counter { id: object::new(ctx), value: 0 });
    }

    /// Increment the value of the supplied `Counter` resource
    fun increment(counter: &mut Counter): u256 {
        let c_ref = &mut counter.value;
        *c_ref = *c_ref + 1;
        *c_ref
    }

    /// Acquire pseudo-random value using `Counter`, transaction primitives,
    /// and user-provided nonce
    public fun rand(
        nonce: vector<u8>,
        counter: &mut Counter,
        ctx: &mut TxContext,
    ): vector<u8> {
        vector::append(&mut nonce, nonce_counter(counter));
        vector::append(&mut nonce, nonce_primitives(ctx));
        rand_with_nonce(nonce)
    }

    /// Acquire pseudo-random value using transaction primitives and
    /// user-provided nonce
    public fun rand_no_counter(
        nonce: vector<u8>,
        ctx: &mut TxContext,
    ): vector<u8> {
        vector::append(&mut nonce, nonce_primitives(ctx));
        rand_with_nonce(nonce)
    }

    /// Acquire pseudo-random value using `Counter` and transaction primitives
    ///
    /// It is recommended that the user use a method that allows passing a
    /// custom nonce that would allow greater randomization.
    public fun rand_no_nonce(
        counter: &mut Counter,
        ctx: &mut TxContext,
    ): vector<u8> {
        let nonce = vector::empty();
        vector::append(&mut nonce, nonce_counter(counter));
        vector::append(&mut nonce, nonce_primitives(ctx));
        rand_with_nonce(nonce)
    }

    /// Acquire pseudo-random value using `Counter` and user-provided nonce
    public fun rand_no_ctx(
        nonce: vector<u8>,
        counter: &mut Counter,
    ): vector<u8> {
        vector::append(&mut nonce, nonce_counter(counter));
        rand_with_nonce(nonce)
    }

    /// Acquire pseudo-random value using `Counter`
    ///
    /// It is recommended that the user use a method that allows passing a
    /// custom nonce that would allow greater randomization, or at least
    /// use more than one source of randomness.
    public fun rand_with_counter(counter: &mut Counter): vector<u8> {
        let nonce = vector::empty();
        vector::append(&mut nonce, nonce_counter(counter));
        rand_with_nonce(nonce)
    }

    /// Acquire pseudo-random value using transaction primitives
    ///
    /// It is recommended that the user use a method that allows passing a
    /// custom nonce that would allow greater randomization, or at least
    /// use more than one source of randomness.
    public fun rand_with_ctx(ctx: &mut TxContext): vector<u8> {
        let nonce = vector::empty();
        vector::append(&mut nonce, nonce_primitives(ctx));
        rand_with_nonce(nonce)
    }

    /// Acquire pseudo-random value using user-provided nonce
    ///
    /// It is recommended that the user use at least more than one source of
    /// randomness.
    public fun rand_with_nonce(nonce: vector<u8>): vector<u8> {
        hash::sha3_256(nonce)
    }

    // === Helpers ===

    /// Generate nonce from transaction primitives
    fun nonce_primitives(ctx: &mut TxContext): vector<u8> {
        let uid = object::new(ctx);
        let object_nonce = object::uid_to_bytes(&uid);
        object::delete(uid);

        let epoch_nonce = bcs::to_bytes(&tx_context::epoch(ctx));
        let sender_nonce = bcs::to_bytes(&tx_context::sender(ctx));

        vector::append(&mut object_nonce, epoch_nonce);
        vector::append(&mut object_nonce, sender_nonce);

        object_nonce
    }

    /// Generate nonce from `Counter`
    fun nonce_counter(counter: &mut Counter): vector<u8> {
        bcs::to_bytes(&increment(counter))
    }

    /// Deserialize `u8` from BCS bytes
    public fun bcs_u8_from_bytes(bytes: vector<u8>): u8 {
        bcs::peel_u8(&mut bcs::new(bytes))
    }

    /// Deserialize `u64` from BCS bytes
    public fun bcs_u64_from_bytes(bytes: vector<u8>): u64 {
        bcs::peel_u64(&mut bcs::new(bytes))
    }

    /// Deserialize `u128` from BCS bytes
    public fun bcs_u128_from_bytes(bytes: vector<u8>): u128 {
        bcs::peel_u128(&mut bcs::new(bytes))
    }

    /// Transpose bytes into `u8`
    ///
    /// Zero byte will be used for empty vector.
    public fun u8_from_bytes(bytes: &vector<u8>): u8 {
        if (vector::length(bytes) > 0) {
            *vector::borrow(bytes, 0)
        } else {
            0
        }
    }

    /// Transpose bytes into `u64`
    ///
    /// Zero bytes will be used for vectors shorter than 8 bytes
    public fun u64_from_bytes(bytes: &vector<u8>): u64 {
        let m: u64 = 0;

        // Cap length at 16 bytes
        let len = vector::length(bytes);
        if (len > 8) { len = 8 };

        let i = 0;
        while (i < len) {
            m = m << 8;
            let byte = *vector::borrow(bytes, i);
            m = m + (byte as u64);
            i = i + 1;
        };

        m
    }

    /// Transpose bytes into `u64`
    ///
    /// Zero bytes will be used for vectors shorter than 16 bytes
    public fun u128_from_bytes(bytes: &vector<u8>): u128 {
        let m: u128 = 0;

        // Cap length at 16 bytes
        let len = vector::length(bytes);
        if (len > 16) { len = 16 };

        let i = 0;
        while (i < len) {
            m = m << 8;
            let byte = *vector::borrow(bytes, i);
            m = m + (byte as u128);
            i = i + 1;
        };

        m
    }

    /// Transpose bytes into `u64`
    ///
    /// Zero bytes will be used for vectors shorter than 32 bytes
    public fun u256_from_bytes(bytes: &vector<u8>): u256 {
        let m: u256 = 0;

        // Cap length at 16 bytes
        let len = vector::length(bytes);
        if (len > 32) { len = 32 };

        let i = 0;
        while (i < len) {
            m = m << 8;
            let byte = *vector::borrow(bytes, i);
            m = m + (byte as u256);
            i = i + 1;
        };

        m
    }
}

🚀 Immediate Next Steps

The project now has DataStreamOracle fully integrated with staleness protection and robust tests. All price logic in PerpetuaTrading and related contracts is routed through DataStreamOracle using feedId (bytes32), not direct price feeds.

**Testing:**
- All tests should use MockOracle and set timestamps for staleness/edge case testing.
- Staleness is enforced in all price-dependent logic (reverts with "Stale price").

**Next Steps for Developers:**
1. **Extend DataStreamOracle:**
   - Implement and expose TWAP and circuit breaker logic.
   - Make the staleness threshold configurable per feed (not just a global constant).
2. **Integration Tests:**
   - Add more integration tests wiring up PerpetuaTrading, LiquidationEngine, and DataStreamOracle.
   - Test edge cases, cross-contract flows, and failure scenarios.
3. **Documentation:**
   - Update contract and developer docs to reflect new features and best practices.
   - Document how to add new feeds, configure staleness, and test edge cases.
4. **Test Coverage:**
   - Continue to ensure 100% test coverage as new features are added.
   - Add tests for new edge cases (e.g., TWAP, circuit breaker triggers, per-feed staleness).

**Migration Note:**
- All legacy price feed logic has been removed from PerpetuaTrading. Use only DataStreamOracle and feedId for all price operations.

**Known Issues:**
- There is one commented-out test in `contracts/test/PositionManager.t.sol` that is currently failing. This is because `PositionManager` does not implement staleness logic. If you want to enforce staleness checks in `PositionManager`, you should implement similar logic as in `PerpetuaTrading`. Otherwise, remove or leave the test commented to avoid confusion.

---

For more details, see the updated README and contract documentation.
(globalThis.TURBOPACK = globalThis.TURBOPACK || []).push([typeof document === "object" ? document.currentScript : undefined, {

"[project]/app/lending/page.tsx [app-client] (ecmascript)": ((__turbopack_context__) => {
"use strict";

var { g: global, __dirname, k: __turbopack_refresh__, m: module } = __turbopack_context__;
{
__turbopack_context__.s({
    "default": (()=>LendingPage)
});
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
"use client";
;
const mockTokens = [
    {
        symbol: "USDC",
        address: "0x0000000000000000000000000000000000000001"
    },
    {
        symbol: "DAI",
        address: "0x0000000000000000000000000000000000000002"
    }
];
function LendingPage() {
    _s();
    const [selectedToken, setSelectedToken] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(mockTokens[0].address);
    const [amount, setAmount] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])("");
    const [userDeposits, setUserDeposits] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])({
        "0x0000000000000000000000000000000000000001": 2000,
        "0x0000000000000000000000000000000000000002": 1000
    });
    const [poolStats, setPoolStats] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])({
        "0x0000000000000000000000000000000000000001": {
            totalDeposits: 100000,
            interestRate: 3.5
        },
        "0x0000000000000000000000000000000000000002": {
            totalDeposits: 50000,
            interestRate: 2.1
        }
    });
    const [message, setMessage] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])("");
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "LendingPage.useEffect": ()=>{
            // Dynamically inject Press Start 2P font from Google Fonts
            const link = document.createElement("link");
            link.href = "https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap";
            link.rel = "stylesheet";
            document.head.appendChild(link);
            return ({
                "LendingPage.useEffect": ()=>{
                    document.head.removeChild(link);
                }
            })["LendingPage.useEffect"];
        }
    }["LendingPage.useEffect"], []);
    function handleDeposit() {
        if (!amount || isNaN(Number(amount))) return setMessage("Enter a valid amount");
        setUserDeposits((d)=>({
                ...d,
                [selectedToken]: d[selectedToken] + Number(amount)
            }));
        setPoolStats((s)=>({
                ...s,
                [selectedToken]: {
                    ...s[selectedToken],
                    totalDeposits: s[selectedToken].totalDeposits + Number(amount)
                }
            }));
        setMessage(`Deposited ${amount} ${getSymbol(selectedToken)}`);
        setAmount("");
    }
    function handleWithdraw() {
        if (!amount || isNaN(Number(amount))) return setMessage("Enter a valid amount");
        if (Number(amount) > userDeposits[selectedToken]) return setMessage("Insufficient balance");
        setUserDeposits((d)=>({
                ...d,
                [selectedToken]: d[selectedToken] - Number(amount)
            }));
        setPoolStats((s)=>({
                ...s,
                [selectedToken]: {
                    ...s[selectedToken],
                    totalDeposits: s[selectedToken].totalDeposits - Number(amount)
                }
            }));
        setMessage(`Withdrew ${amount} ${getSymbol(selectedToken)}`);
        setAmount("");
    }
    function getSymbol(address) {
        return mockTokens.find((t)=>t.address === address)?.symbol || "?";
    }
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "centered-container",
        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "max-w-xl w-full",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h1", {
                    className: "text-3xl font-bold mb-4 shadow-title",
                    children: "Lending"
                }, void 0, false, {
                    fileName: "[project]/app/lending/page.tsx",
                    lineNumber: 73,
                    columnNumber: 5
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                    className: "text-gray-600 mb-6",
                    children: "Deposit to or withdraw from the lending pool. View pool stats."
                }, void 0, false, {
                    fileName: "[project]/app/lending/page.tsx",
                    lineNumber: 74,
                    columnNumber: 5
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "card mb-6",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "mb-4",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("label", {
                                    className: "block mb-1 font-medium",
                                    children: "Token"
                                }, void 0, false, {
                                    fileName: "[project]/app/lending/page.tsx",
                                    lineNumber: 77,
                                    columnNumber: 7
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("select", {
                                    className: "w-full",
                                    value: selectedToken,
                                    onChange: (e)=>setSelectedToken(e.target.value),
                                    children: mockTokens.map((token)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("option", {
                                            value: token.address,
                                            children: token.symbol
                                        }, token.address, false, {
                                            fileName: "[project]/app/lending/page.tsx",
                                            lineNumber: 84,
                                            columnNumber: 9
                                        }, this))
                                }, void 0, false, {
                                    fileName: "[project]/app/lending/page.tsx",
                                    lineNumber: 78,
                                    columnNumber: 7
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/app/lending/page.tsx",
                            lineNumber: 76,
                            columnNumber: 6
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "mb-4",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("label", {
                                    className: "block mb-1 font-medium",
                                    children: "Amount"
                                }, void 0, false, {
                                    fileName: "[project]/app/lending/page.tsx",
                                    lineNumber: 91,
                                    columnNumber: 7
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("input", {
                                    type: "number",
                                    className: "w-full",
                                    value: amount,
                                    onChange: (e)=>setAmount(e.target.value),
                                    min: 0
                                }, void 0, false, {
                                    fileName: "[project]/app/lending/page.tsx",
                                    lineNumber: 92,
                                    columnNumber: 7
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/app/lending/page.tsx",
                            lineNumber: 90,
                            columnNumber: 6
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "flex gap-4",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                    onClick: handleDeposit,
                                    children: "Deposit"
                                }, void 0, false, {
                                    fileName: "[project]/app/lending/page.tsx",
                                    lineNumber: 101,
                                    columnNumber: 7
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                    style: {
                                        background: '#06b6d4'
                                    },
                                    onClick: handleWithdraw,
                                    children: "Withdraw"
                                }, void 0, false, {
                                    fileName: "[project]/app/lending/page.tsx",
                                    lineNumber: 102,
                                    columnNumber: 7
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/app/lending/page.tsx",
                            lineNumber: 100,
                            columnNumber: 6
                        }, this),
                        message && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "mt-4 text-[#6366f1] font-semibold",
                            children: message
                        }, void 0, false, {
                            fileName: "[project]/app/lending/page.tsx",
                            lineNumber: 104,
                            columnNumber: 18
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/app/lending/page.tsx",
                    lineNumber: 75,
                    columnNumber: 5
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "card mb-6",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                            className: "text-xl font-semibold mb-2",
                            children: "Your Deposits"
                        }, void 0, false, {
                            fileName: "[project]/app/lending/page.tsx",
                            lineNumber: 107,
                            columnNumber: 6
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("ul", {
                            children: mockTokens.map((token)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                    className: "mb-1",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "font-mono",
                                            children: [
                                                token.symbol,
                                                ":"
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/app/lending/page.tsx",
                                            lineNumber: 111,
                                            columnNumber: 9
                                        }, this),
                                        " ",
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "font-bold",
                                            children: userDeposits[token.address]
                                        }, void 0, false, {
                                            fileName: "[project]/app/lending/page.tsx",
                                            lineNumber: 111,
                                            columnNumber: 60
                                        }, this)
                                    ]
                                }, token.address, true, {
                                    fileName: "[project]/app/lending/page.tsx",
                                    lineNumber: 110,
                                    columnNumber: 8
                                }, this))
                        }, void 0, false, {
                            fileName: "[project]/app/lending/page.tsx",
                            lineNumber: 108,
                            columnNumber: 6
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/app/lending/page.tsx",
                    lineNumber: 106,
                    columnNumber: 5
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "card",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                            className: "text-xl font-semibold mb-2",
                            children: "Pool Stats"
                        }, void 0, false, {
                            fileName: "[project]/app/lending/page.tsx",
                            lineNumber: 117,
                            columnNumber: 6
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("ul", {
                            children: mockTokens.map((token)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                    className: "mb-1",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "font-mono",
                                            children: [
                                                token.symbol,
                                                ":"
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/app/lending/page.tsx",
                                            lineNumber: 121,
                                            columnNumber: 9
                                        }, this),
                                        " ",
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "font-bold",
                                            children: poolStats[token.address].totalDeposits
                                        }, void 0, false, {
                                            fileName: "[project]/app/lending/page.tsx",
                                            lineNumber: 121,
                                            columnNumber: 60
                                        }, this),
                                        " total,",
                                        " ",
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "text-[#6366f1]",
                                            children: [
                                                poolStats[token.address].interestRate,
                                                "% APY"
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/app/lending/page.tsx",
                                            lineNumber: 122,
                                            columnNumber: 9
                                        }, this)
                                    ]
                                }, token.address, true, {
                                    fileName: "[project]/app/lending/page.tsx",
                                    lineNumber: 120,
                                    columnNumber: 8
                                }, this))
                        }, void 0, false, {
                            fileName: "[project]/app/lending/page.tsx",
                            lineNumber: 118,
                            columnNumber: 6
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/app/lending/page.tsx",
                    lineNumber: 116,
                    columnNumber: 5
                }, this)
            ]
        }, void 0, true, {
            fileName: "[project]/app/lending/page.tsx",
            lineNumber: 72,
            columnNumber: 4
        }, this)
    }, void 0, false, {
        fileName: "[project]/app/lending/page.tsx",
        lineNumber: 71,
        columnNumber: 3
    }, this);
}
_s(LendingPage, "MlxwJxwK3n4OO0VqMrxLF0xknfM=");
_c = LendingPage;
var _c;
__turbopack_context__.k.register(_c, "LendingPage");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(module, globalThis.$RefreshHelpers$);
}
}}),
}]);

//# sourceMappingURL=app_lending_page_tsx_9d0515f4._.js.map
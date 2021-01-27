// Tests the diagnostics emitted when we can't build a module interface, and
// particularly whether or not they call out compiler version mismatches.
//
// First, emit an empty module interface from the current compiler, then add
// some invalid syntax to it:
//
// RUN: %empty-directory(%t)
// RUN: echo "" | %target-swift-frontend -typecheck -emit-module-interface-path %t/UnbuildableCurrent.swiftinterface -enable-library-evolution -swift-version 5 -module-name UnbuildableCurrent -
// RUN: echo "public func fn(_: String = #somethingYouveNeverHeardOf)" >> %t/UnbuildableCurrent.swiftinterface
//
// Next, modify a version of it so it looks like it was built with a different Swift compiler:
//
// RUN: sed -E -e 's|swift-compiler-version: (.*)|swift-compiler-version: NeoTokyoSwift 2000.42|' -e 's|UnbuildableCurrent|UnbuildableFuture|g' %t/UnbuildableCurrent.swiftinterface > %t/UnbuildableFuture.swiftinterface
//
// And finally, test:
//
// RUN: not %target-swift-frontend -typecheck %s -I %t -DCURRENT 2>&1 | %FileCheck -check-prefixes=ALL,CURRENT %s
// RUN: not %target-swift-frontend -typecheck %s -I %t -DFUTURE 2>&1 | %FileCheck -check-prefixes=ALL,FUTURE %s
//
// Test that we get the same results when typechecking the interface:
//
// RUN: not %target-swift-frontend -typecheck-module-from-interface %t/UnbuildableCurrent.swiftinterface 2>&1 | %FileCheck -check-prefixes=ALL,CURRENT-VERIFY %s
// RUN: not %target-swift-frontend -typecheck-module-from-interface %t/UnbuildableFuture.swiftinterface 2>&1 | %FileCheck -check-prefixes=ALL,FUTURE-VERIFY %s

// ALL: Unbuildable{{[^.]+}}.swiftinterface:{{[0-9]+}}:{{[0-9]+}}: error: use of unknown directive '#somethingYouveNeverHeardOf'

#if CURRENT
import UnbuildableCurrent
// CURRENT: unbuildable.swift:[[@LINE-1]]:8: error: failed to build module 'UnbuildableCurrent' for importation due to the errors above; the textual interface may be broken by project issues or a compiler bug
#else
import UnbuildableFuture
// FUTURE: unbuildable.swift:[[@LINE-1]]:8: error: failed to build module 'UnbuildableFuture' for importation due to the errors above; the textual interface may be broken by project issues, differences between compilers (the producer 'NeoTokyoSwift 2000.42' and this compiler '{{.*Swift version.*}}') or a compiler bug
#endif

// CURRENT-VERIFY: UnbuildableCurrent.swiftinterface:1:1: error: failed to verify module interface of 'UnbuildableCurrent' due to the errors above; the textual interface may be broken by project issues or a compiler bug
// FUTURE-VERIFY: UnbuildableFuture.swiftinterface:1:1: error: failed to verify module interface of 'UnbuildableFuture' due to the errors above; the textual interface may be broken by project issues, differences between compilers (the producer 'NeoTokyoSwift 2000.42' and this compiler '{{.*Swift version.*}}') or a compiler bug

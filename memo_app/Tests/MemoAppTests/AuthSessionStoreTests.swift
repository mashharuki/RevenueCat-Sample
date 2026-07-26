import XCTest
@testable import MemoApp

@MainActor
final class AuthSessionStoreTests: XCTestCase {
  func testSessionIsNilBeforeStartListening() {
    let store = AuthSessionStore(authStateProvider: FakeAuthStateObserving())

    XCTAssertNil(store.session)
  }

  func testStartListeningSetsSessionWhenAuthStateEmitsAUser() {
    let observer = FakeAuthStateObserving()
    let store = AuthSessionStore(authStateProvider: observer)

    store.startListening()
    observer.emit(AuthenticatedSession(uid: "uid-1", displayName: "Ada"))

    XCTAssertEqual(store.session, AuthenticatedSession(uid: "uid-1", displayName: "Ada"))
  }

  func testAuthStateEmittingNilClearsTheSessionOnSignOut() {
    let observer = FakeAuthStateObserving()
    let store = AuthSessionStore(authStateProvider: observer)
    store.startListening()
    observer.emit(AuthenticatedSession(uid: "uid-1", displayName: "Ada"))
    XCTAssertNotNil(store.session)

    observer.emit(nil)

    XCTAssertNil(store.session)
  }

  func testStartListeningTwiceDoesNotRegisterASecondObserver() {
    let observer = FakeAuthStateObserving()
    let store = AuthSessionStore(authStateProvider: observer)

    store.startListening()
    store.startListening()

    XCTAssertEqual(observer.observeCallCount, 1)
  }

  func testStopListeningStopsReflectingFurtherAuthStateChanges() {
    let observer = FakeAuthStateObserving()
    let store = AuthSessionStore(authStateProvider: observer)
    store.startListening()
    observer.emit(AuthenticatedSession(uid: "uid-1", displayName: "Ada"))

    store.stopListening()
    observer.emit(AuthenticatedSession(uid: "uid-2", displayName: "Grace"))

    XCTAssertEqual(observer.removeCallCount, 1)
    XCTAssertEqual(store.session, AuthenticatedSession(uid: "uid-1", displayName: "Ada"))
  }
}

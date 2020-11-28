import XCTest
@testable import ReactiveSubject

import Combine

final class TestSubject: ReactiveSubject {
  typealias Output = Int
  typealias Failure = Never
  let queue = DispatchQueue(label: "TestSubject")
  var subscriptions = Subscriptions() {
    didSet {
      if let expectation = unsubscribeExpectation, subscriptions.minDemand == .none {
        expectation.fulfill()
        unsubscribeExpectation = nil
      }
    }
  }
  var unsubscribeExpectation: XCTestExpectation?
}

final class ReactiveSubjectTests: XCTestCase {
  func testReactiveSubject() {
    let subject = TestSubject()
    var received: [Int] = []
    let unsubscribeExpectation = expectation(description: "unsubscribe")
    var cancellable: AnyCancellable?
    subject.queue.async {
      cancellable = subject.sink(receiveValue: { received.append($0) })
      XCTAssertEqual(subject.subscriptions.minDemand, .unlimited)
      subject.send(4)
      subject.send(3)
      subject.send(2)
      subject.send(1)
      subject.unsubscribeExpectation = unsubscribeExpectation
      cancellable?.cancel()
    }
    waitForExpectations(timeout: 1) { error in
      XCTAssertNil(error)
      XCTAssertEqual(received, [4,3,2,1])
      XCTAssertEqual(subject.subscriptions.minDemand, .none)
    }
  }
  
  func testCompletion() {
    let subject = TestSubject()
    var received: [Int] = []
    let unsubscribeExpectation = expectation(description: "unsubscribe")
    var cancellable: AnyCancellable?
    subject.queue.async {
      cancellable = subject.sink(receiveValue: { received.append($0) })
      XCTAssertEqual(subject.subscriptions.minDemand, .unlimited)
      subject.send(4)
      subject.send(3)
      subject.send(2)
      subject.send(1)
      subject.unsubscribeExpectation = unsubscribeExpectation
      subject.send(completion: .finished)
    }
    waitForExpectations(timeout: 1) { error in
      XCTAssertNil(error)
      XCTAssertEqual(received, [4,3,2,1])
      XCTAssertEqual(subject.subscriptions.minDemand, .none)
      _ = cancellable
    }
  }
}

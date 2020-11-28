
import Combine
import Foundation

public protocol ReactiveSubject: Subject {
  associatedtype Output
  associatedtype Failure
  var subscriptions: Subscriptions { get set }
  var queue: DispatchQueue { get }
}

public extension ReactiveSubject {
  typealias Subscriptions = _ReactiveSubjectSubscriptions<Self>
  func send(_ value: Output) {
    dispatchPrecondition(condition: .onQueue(queue))
    for subscription in subscriptions.subscriptions.values {
      subscription.send(value)
    }
  }
  func send(completion: Subscribers.Completion<Failure>) {
    dispatchPrecondition(condition: .onQueue(queue))
    for subscription in subscriptions.subscriptions.values {
      subscription.send(completion: completion)
    }
  }
  
  func send(subscription: Combine.Subscription) {
    /// I'm not sure what this does
    assertionFailure()
  }
  func receive<S: Subscriber>(subscriber: S)
  where
    S.Input == Output,
    S.Failure == Failure
  {
    let subscription = Subscription(subject: self, subscriber: subscriber)
    subscriptions.subscriptions[subscription.combineIdentifier] = subscription
    subscriber.receive(subscription: subscription)
  }
  
  var queue: DispatchQueue { .main }
}

public struct _ReactiveSubjectSubscriptions<Subject: ReactiveSubject>: Sequence {
  public init() { }
  
  public struct SubscriptionInfo {
    public let demand: Subscribers.Demand
  }
  
  public var minDemand: Subscribers.Demand {
    map(\.demand).min() ?? .none
  }
  
  public struct Iterator: IteratorProtocol {
    public mutating func next() -> SubscriptionInfo? {
      while let next = parent.next() {
        guard let demand = next.value.state?.demand else { continue }
        return SubscriptionInfo(demand: demand)
      }
      return nil
    }
    fileprivate var parent: Dictionary<CombineIdentifier, Subscription<Subject>>.Iterator
  }
  public func makeIterator() -> Iterator {
    return Iterator(parent: subscriptions.makeIterator())
  }
  
  fileprivate typealias Subscriptions = Self
  fileprivate mutating func subscriptionRequestedDemand(_ id: CombineIdentifier) {
    /// This method only exists to trigger `didSet` on the owning `ReactiveSubject`
  }
  fileprivate mutating func subscriptionCancelled(_ id: CombineIdentifier) {
    subscriptions.removeValue(forKey: id)
  }
  fileprivate var subscriptions: [CombineIdentifier: Subscription<Subject>] = [:]
}

private final class Subscription<Subject: ReactiveSubject>: Combine.Subscription {
  init<S: Subscriber>(subject: Subject, subscriber: S)
  where
    S.Input == Subject.Output,
    S.Failure == Subject.Failure
  {
    self.state = .init(subject: subject, subscriber: AnySubscriber(subscriber))
  }
  func request(_ demand: Subscribers.Demand) {
    guard let state = state else { return }
    dispatchPrecondition(condition: .onQueue(state.subject.queue))
    // TODO: I'm not sure if this should be `+=` or `=`
    self.state?.demand += demand
    state.subject.subscriptions.subscriptionRequestedDemand(combineIdentifier)
  }
  func cancel() {
    state?.subject.queue.async { [weak self] in
      guard let self = self else { return }
      self.state?.subject.subscriptions.subscriptionCancelled(self.combineIdentifier)
      self.state = nil
    }
  }
  struct ActiveState {
    let subject: Subject
    let subscriber: AnySubscriber<Subject.Output, Subject.Failure>
    var demand: Subscribers.Demand = .none
  }
  var state: ActiveState?
  
  fileprivate func send(_ value: Subject.Output) {
    guard let state = state else { return }
    dispatchPrecondition(condition: .onQueue(state.subject.queue))
    // TODO: I'm not sure if this should be `+=` or `=`
    self.state?.demand += state.subscriber.receive(value)
  }
  fileprivate func send(completion: Subscribers.Completion<Subject.Failure>) {
    guard let state = state else { return }
    dispatchPrecondition(condition: .onQueue(state.subject.queue))
    state.subscriber.receive(completion: completion)
  }
}


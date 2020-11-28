# ReactiveSubject

Implements a Combine subject which can track its subscriptions. This is useful if a subject wants to react to its subscription state changing, for example by starting or stopping an `AVCaptureSession`.

To use, simply conform your type to `ReactiveSubject` and implement whatever logic you need as a `didSet` handler on the `subscriptions` property.

An example of this can be found in the tests.

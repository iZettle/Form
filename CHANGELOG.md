## 1.10.5
- Bugfix: Fixed scroll-to-top not working correctly.
- Addition: Add new initializers for TableKit and CollectionKit that have an explicit `holdIn` parameter to keep subscriptions.
- Change: Change the deprecation warning of TableKit and CollectionKit initializers to point to the new ones

## 1.10.4
- Bugfix: Fix issue with ui refresh deadlock
- Change: Deprecated `thinestLineWidth`, which has been renamed to `hairlineWidth`.

## 1.10.3
- Bugfix: Fix table section header/footer height calculation on iOS 10

## 1.10.2
- Bugfix: Fix scrollview top pinning on iOS 11 and later where currently if the scrollview is in a navigation controller there is a gap between the scrollview top and the pinned view 

## 1.10.1
- Bugfix: Apply view styling based on initial trait collection to prevent bugs where styling is not applied if the initial trait collection did not change

## 1.10.0
- `TableKit` and `CollectionKit` do no longer require the passing of a bag to their initializers. This means that the life-time of a kit instance is no longer kept alive by a provided bag. For most usages that should not change the behaviour but if the kit is prematurely deallocted you can always explicity hold on to it `bag.hold(kit)`.
- `TableKit`'s and `CollectionKit`'s initializers taking a bag parameter have been deprecated. Instead use the new initializers introduced above.

## 1.9.1
- Bugfix: fix pinning a view to a scrollview on iOS 9 and 10 (issue [#104](https://github.com/iZettle/Form/issues/104))
- Layout fix: properly layout multiline row view titles

## 1.9.0
- Bugfix: Make sure to remove the old empty state view from a table after setting a new empty state view [#99](https://github.com/iZettle/Form/issues/99).
- Add minimum scale factor to TextStyle. When a custom value is set that can also affect other controls using TextStyle, e.g UIButton.

## 1.8.0
- Migrate to swift 5

## 1.7.1
- Bugfix: Fix UILabel styling bug when a styled label's text is set to nil and then updating its value does nothing.

## 1.7.0
- Adds new `HeaderFooterReusable` protocol to allow providing separate `Reusable` types for rendering a section's header and footer.
- Adds letter spacing and line height to `TextStyle`.
- Adds target offset to `willEndDragging` signal of `ScrollViewDelegate`.
- Adds will display cell signal to `CollectionViewDelegate`.

## 1.6.3
- Performace. Added custom `count` implementation for `TableSection` to improve performance of e.g. `Table.isValidIndex` that might be called a lot for large tables.

## 1.6.2
- Bugfix: Setting `table` direclty on `TableKit` or `CollectionKit` did not reload the view correctly with the updated table.

## 1.6.1
- Bugfix: Fix layout problem caused by pinning a view to UITransitionView that is no longer shown on iOS 9/10
- Bugfix: Activate constraints before calls to layoutIfNeeded to prevent crashes on iOS 9/10 when embedding views in a scrollView

## 1.6.0
- Add sizeForItemAt for CollectionViewDelegate
- Bugfix: Fix table view cells reorder control position to respect insets

## 1.5.0
- Add optional preferred minimum size to ButtonStyle

## 1.4.1
- Fix a bug that avoids the crash when styling is tried on UITableViewCell that was created without the associated variable
- Revert a fix for `estimatedSectionHeaderHeight` / `estimatedSectionFooterHeight` that caused bug in Form insets.
- Fix cell background missing issue when inserting cell on iOS 9


## 1.4

- Added `TextFieldDelegate` similar to `ScrollViewDelegate` and friends.
- Added `UITextField` and `UIScrollView` `install()` delegate helpers.
- Added remaining methods to `ScrollViewDelegete`.
- Added `GestureRecognizerDelegate`.
- Fixed a bug in `UIScrollView.adjustContentOffset` for scrollviews with a non-zero `frame.origin.y`.

## 1.3.3
- Bugfix: Remove hardcoded value used for determing smallest resizable image size causing not smooth borders of rounded images
- Bugfix: Fix a bug where highligted segment turns gray if it's also selected
- Bugfix: Add extra space to the resizable image rect to prevent the border taking the whole image

## 1.3.2

- Bugfix: Fixed issue where update indices in `TableChange` and `ChangeStep` were specified in the new array rather than the orignal array
- Bugfix: Fixed crash in UICollectoinView when animating section and row changes at the same time
- Bugfix: Make sure `[animated keyPath:]` is animated with `.allowUserInteraction`.

## 1.3.1

- Bugfix: Fixed issue where out of range `UIViewAnimationCurve` enum values caused a crash running on Xcode 10 and iOS 12.
- Bugfix: `TextStyle`: Don't change text color on highlight if `highlightedColor` is not set explicitly.
- Bugfix: Updated `ValueField` to post `UITextField` notifications to better participate in e.g. keyboard avoidance.

## 1.3

- Added reordering delegate `reordering` to `CollectionViewDelegate`.
- Added `apply(changes:)` to `MutableCollection`, `TableKit` and `CollectionKit`.

- Fixed a `TableKit` crash on iOS 9.
- Fixed a compiler "unable to type-check this expression in reasonable time" on Swift 4.2.

## 1.2

- Added `reuseIdentifier` to the `Reusable` protocol to allow better handling of tables with mixed types.
- Added `Either` conditional conformance to `Reusable` when `Left` and `Right` conforms to `Reusable`.
- Added alternative helper type `MixedReusable` that can be used instead of `Either` for tables with mixed types.
- Extended the Demo sample with examples show-casing using tables with mixed types.
- Added new table and collection view overloads of dequeueCell taking a re-configure closure.
- Added didEndDisplayingCell signal to TableViewDelegate

- Deprecating `EitherRow`, replaced by using Flows `Either` instead
- Deprecating `dequeueCell(forItem:, style:, reuseIdentifier:)`, replaced by version not using explicit `reuseIdentifier`

- Fixed issue where Reusable configure was called instead of reconfigure when rows was updated.
- Bugfix: Updated TableKit to release the a cell's bag once the cell ends displaying or the TableKit's bag is being disposed.

## 1.1.0
- Adds a ScrollViewDelegate class implementing the UIScrollViewDelegate protocol
- Updates NumberEditor to handle entering and editing of negative value
- Disables autocorrection for ValueField by defualt
- Adds a new API for providing view for empty table view state which pins it to the edges of the table view. The old API that is using hardcoded insets and doesn't pin all edges is now deprecated.

## 1.0.2

- Fixes a bug with `install` view(s) into scroll views where the content fits but the scroll view still won't scroll even though `InstallOptions.disableScrollingIfContentFits`` was not provided.
- Deprecated disableScrollingIfContentFits() as this is better supported by UIScrollViews's alwaysBounceVertical = false
- Fixes a bug in SelectView where tapping inside but releasing outside would call the callback or find first responder`.
- Fixes bug where SectionView's rows minHeight constraint would not be set up correctly when some rows are hidden.

## 1.0.1

- Updated podspec to allow using features behind canImport(Presentation)

# 1.0

This is the first public release of the Form library.

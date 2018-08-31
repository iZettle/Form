## 1.2

- Added `reuseIdentifier` to the `Reusable` protocol to allow better handling of tables with mixed types.
- Added `Either` conditional conformance to `Reusable` when `Left` and `Right` conforms to `Reusable`.
- Added alternative helper type `MixedReusable` that can be used instead of `Either` for tables with mixed types.
- Extended the Demo sample with examples show-casing using tables with mixed types.
- Added new table and collection view overloads of dequeueCell taking a re-configure closure.

- Deprecating `EitherRow`, replaced by using Flows `Either` instead 
- Deprecating `dequeueCell(forItem:, style:, reuseIdentifier:)`, replaced by version not using explicit `reuseIdentifier`

- Fixed issue where Reusable configure as called instead of reconfigure when rows was updated.

## 1.1.1
- Added didEndDisplayingCell signal to TableViewDelegate
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

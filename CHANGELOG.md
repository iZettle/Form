## 1.0.2

- Fixes a bug with `install` view(s) into scroll views where the content fits but the scroll view still won't scroll even though `InstallOptions.disableScrollingIfContentFits`` was not provided.
- Deprecated disableScrollingIfContentFits() as this is better supported by UIScrollViews's alwaysBounceVertical = false
- Fixes a bug in SelectView where tapping inside but releasing outside would call the callback or find first responder`.
- Fixes bug where SectionView's rows minHeight constraint would not be set up correctly when some rows are hidden.

## 1.0.1

- Updated podspec to allow using features behind canImport(Presentation) 

# 1.0

This is the first public release of the Form library.

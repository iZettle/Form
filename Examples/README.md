## Examples

This is the list of projects showcasing the tools provided by Form:
- [Demo](Demo/)
- [Messages](Messages/)

All examples are integrated and built with Form as part of our CI.
We also use some of them for running integration UI tests.

### Running an example
To run one any of the projects **you need to integrate it with Form first**. All projects come with a predefined [CocoaPods](https://github.com/CocoaPods/CocoaPods) dependency so you can just run `pod insall` in the project's folder and then use the generated workspace. Alternatively you can use another way for dependency management of your choice.

### Adding new example
To add a new example create a folder with a descriptive name and add a new project called **Example** to it as well as a **README** describing it.

Make sure to add a `Podfile` pointing to the Form's podspec location:
```
pod 'FormFramework', :path => '../..'
```

Why all projects are called `Example`? We chose to follow the same naming convention as it makes it easy to [iterate through them and apply actions](https://github.com/iZettle/Form/blob/master/build.sh#L50) (like `build` and `test`). We use this approach across all of the iOS frameworks we open sourced.

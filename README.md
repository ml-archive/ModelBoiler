![Logo](https://raw.githubusercontent.com/nodes-ios/ModelBoiler/master/Model%20Boiler/Resources/Assets.xcassets/AppIcon.appiconset/Model%20Boiler_128.png)

# Model Boiler

[![Travis](https://img.shields.io/travis/nodes-ios/ModelBoiler.svg)](https://travis-ci.org/nodes-ios/ModelBoiler)
![Plaform](https://img.shields.io/badge/platform-macOS-brightgreen.svg)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/nodes-ios/ModelBoiler/blob/master/LICENSE)


**Model Boiler** is a macOS application used to quickly generate model boilerplate code for models using [🐍 Serpent](https://github.com/nodes-ios/Serpent) and the `Serializable` protocol.

![Gif](modelboiler.gif)

## 📦 Installation

### Homebrew Cask

1. Run this command in your terminal

~~~bash
brew cask install model-boiler
~~~

### Release
1. Head over to the [latest release](https://github.com/nodes-ios/ModelBoiler/releases/latest).
2. Download the `Model Boiler.app.zip`.
3. Unzip & open the executable file.

### Manual
1. Download or clone the repository.
2. Install the dependencies by running `carthage bootstrap --platform osx` from the unzipped folder in your terminal.
3. Open the `Model Boiler.xcodeproj`.
4. Archive.
5. Choose Export ("Save Built Products" option) in the Organizer window.
6. Open the executable located at:  

~~~
~/Desktop/Model Boiler {DATE}/Products/Applications/Model Boiler.app
~~~


## 💻 Usage

Model Boiler is a menu bar application, meaning that you won't find it's icon in the Dock. If you want to access the settings, update or quit Model Boiler then look for the icon in the top menu bar on the right side.

### Generating Code

1. Select your model code
2. Press the Model Boiler shortcut (can be customized in settings)
3. Paste the generated code
4. Profit!

### Settings

**Key case conversion** is one of the features of Model Boiler, which allows you to easily convert your key names from `yourProperty` to `your_property`. (note: this is overriden if custom key is specified)

**Custom shortcut** can be configured in the settings window of Model Boiler and the default shortcut is `⌘ + §`.

### Key Override

There is a hidden feature of Model Boiler that allows you to override the property key that should be used in the generated code. To be able to override the key just write a comment on the same line where your property is declared like this:

~~~swift
var name = "" // <-customNameKey
~~~

This will then use the specified key in the generated code. However, note that this will override all other key modifications that Model Boiler normally does (like automatic camelCase -> snake_case conversion).


**Note:** Model Boiler currently doesn't support nested structs. You will need to generate boilerplate code for your nested structs separately.

## :octocat: Dependencies
#### [Serpent](https://github.com/nodes-ios/Serpent)  
> A protocol to serialize Swift structs and classes for encoding and decoding. 

You will need this dependency if you want to use the generated boiler plate code.
   
####[model-generator](https://github.com/nodes-ios/model-generator)  
The underlying framework used for the actual generation of the code. Can be also used as a command line tool if you choose to go all nerd.

## 👥 Credits
Made with ❤️ at [Nodes](http://nodesagency.com).

## 📄 License
**Model Boiler** is available under the MIT license. See the [LICENSE](https://github.com/nodes-ios/ModelBoiler/blob/master/LICENSE) file for more info.

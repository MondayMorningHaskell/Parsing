# Parsing

Welcome to the companion Github repository for our [Parsing series](https://www.mmhaskell.com/parsing) on the Monday Morning Haskell blog! In this series, we explore a few different libraries for parsing strings into Haskell data structures.

## [Gherkin Syntax](https://www.mmhaskell.com/parsing/gherkin)

Our overarching example for this series is [Gherkin Syntax](https://cucumber.io/docs/gherkin). This is a special syntax that allows us to describe a set of test behaviors for our program. We have a few example files you can observe in [this directory](https://github.com/MondayMorningHaskell/Parsing/tree/master/test/features) that are written in Gerkhin syntax. Our main objective in this series is to parse each of these files into the Haskell data types described [in this module](https://github.com/MondayMorningHaskell/Parsing/blob/master/src/Types.hs).

The examples all relate to a fake "banking" application. So you can also observe the expected results in these files:

* [Registration Feature](https://github.com/MondayMorningHaskell/Parsing/blob/master/test/TestRegistrationFeatures.hs)
* [Login Feature](https://github.com/MondayMorningHaskell/Parsing/blob/master/test/TestLoginFeatures.hs)
* [Withdrawal Feature](https://github.com/MondayMorningHaskell/Parsing/blob/master/test/TestWithdrawalFeatures.hs)

We use these files as the expected output for some unit tests.

## Running the Test Code

To run the code, you just have to start by building it:

```bash
>> stack build
```

We try three different parsing libraries: Applicative Regex Parsing, Attoparsec, and Megaparsec. There's a test suite corresponding to each of these libraries:

```bash
>> stack build Parsing:test:regex-tests
>> stack build Parsing:test:atto-tests
>> stack build Parsing:test:mega-tests
```

For the 3 primary articles in the series, you can follow along with the code examples and try making changes. You can run the tests to see if you still get the correct results. Just take a look at the proper source module:

* [Part 2](https://mmhaskell.com/parsing/regex) - [RegexParser](https://github.com/MondayMorningHaskell/Parsing/blob/master/blob/src/RegexParser.hs)
* [Part 3](https://mmhaskell.com/parsing/attoparsec) - [AttoParser](https://github.com/MondayMorningHaskell/Parsing/blob/master/blob/src/AttoParser.hs)
* [Part 4](https://mmhaskell.com/parsing/megaparsec) - [MegaParser](https://github.com/MondayMorningHaskell/Parsing/blob/master/blob/src/MegaParser.hs)

## Extending this Project

There are a few different ways you can extend this repository if you want to do some of your own practicing with these libraries. Here are a couple ideas:

1. Try extending one or more of the parsers so it can handle more features of Gherkin syntax. Remember to use test driven development!
2. Make use of the Haskell data structures in some way. Run some code based on what you've parsed! For example, in [Cucumber](https://cucumber.io/tools), each feature test can be used to perform test assertions.

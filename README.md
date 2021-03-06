# hascard
A minimal commandline utility for reviewing notes. 'Flashcards' can be written in markdown-like syntax.

![a recording of example usage of the hascard application](./recordings/recording.gif)

## Contents
- [Installation](#installation)
- [Cards](#cards)
- [Miscellaneous info](#miscellaneous-info)

## Installation
### Binary
The binary used on my system is available under [releases](https://github.com/Yvee1/hascard/releases/). If you run debian with the x86-64 architecture that binary should work for you too. To be able to run it from any directory, it has to be added to the PATH. This can be done by copying it to e.g. the `/usr/local/bin` directory.

### Snapcraft
Hascard is also on [snapcraft](https://snapcraft.io/hascard). Installation instructions are on that site. If you already have snap installed you can just install hascard via `sudo snap install hascard`. By default snap applications are isolated from the system and run in a sandbox. This means that hascard does not have permission to read or write any files on the system aside from those under `%HOME/snap/hascard`. To be able to read cards also in other directories under the home directory, hascard makes use of the `home` interface which might need to be enabled manually using `sudo snap connect hascard:home :home`.

### Install from source
Another option is to build hascard and install it from source. For this you need stack (installation instructions are [here](https://docs.haskellstack.org/en/stable/README/#how-to-install)). Then for example clone this repository somewhere and issue `stack install`:
```
git clone https://github.com/Yvee1/hascard.git
cd hascard
stack install hascard
```

## Cards
Decks of cards are written in `.txt` files. Cards are seperated with a line containing three dashes `---`. For examples, see the [`/cards`](https://github.com/Yvee1/hascard/tree/master/cards) directory. In this section the 4 different cards are listed, with the syntax and how it is represented in the application.

### Definition
This is the simplest card, it simply has a title and can be flipped to show the contents. For example the following card
```
# Word or question
Explanation or definition of this word, or the answer to the question.
```
will result in
![](./recordings/definition.gif)

### Multiple choice
This is a typical multiple choice question. The question starts with a `#` and the choices follow. Only one answer is correct, and is indicated by a `*`, the other questions are preceded by a `-`. As an example, the following text

```
# Multiple choice question, (only one answer is right)
- Choice 1
* Choice 2 (this is the correct answer)
- Choice 3
- Choice 4
```

gets rendered as
![](./recordings/multiple-choice.gif)

### Multiple answer
Multiple choice questions with multiple possible answers is also possible. Here again the question starts with `#` and the options follow. Preceding each option is a box `[ ]` that is filled with a `*` or a `x` if it is correct. For example

```
# Multiple answer question
[*] Option 1 (this is a correct answer)
[ ] Option 2
[*] Option 3 (this is a correct answer)
[ ] Option 4
```
results in
![](./recordings/multiple-answer.gif)

### Open question
Open questions are also supported. The words that have to be filled in should be surrounded by underscores `_`. Multiple answer possibilities can also be given by seperating them with vertical bars `|`. As an example, the card

```
# Fill in the gaps
The symbol € is for the currency named _Euro_, and is used in the _EU|European Union_.
```
behaves like this
![](./recordings/gapped-question.gif)

## Miscellaneous info
Written in Haskell, UI built with [brick](https://github.com/jtdaugherty/brick) and parsing of cards done with [parsec](https://github.com/haskell/parsec). Recordings of the terminal were made using [terminalizer](https://github.com/faressoft/terminalizer).

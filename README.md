# Puppy Buffer Combinator

The purpose of this mod is to achieve a zero UPS combinator which is specialised to computing buffer sizes.

## How to use it

After researching the circuit network, you will receive a new entity, the Buffer Combinator. This costs just one constant combinator and one green circuit. When you place the combinator and click to open the GUI, you will receive a custom UI which lets you set the buffer sizes. The typical usage is to fill in the buffer size and then blueprint e.g. a train station. When you set the item type, it calculates the proper stack size for you. This calculation is a one-off at configuration time so has no ongoing cost. To connect it to the circuit network, use the regular constant combinator connectivity. The UI allows you to pick signals as the item type, but in this case, no signal will be generated; it must be an item or a fluid.

## Known limitations

If you destroy a buffer combinator and then undo, a buffer combinator will be placed but the settings are lost.
Can't prevent the user from picking something that's not an item or a fluid.

## Current status

This is the first release of my first mod, although I've stolen a lot of code from people more experienced than me. It works as far as I've tested it which is strictly not very much. If you encounter any issues, please raise a GH issue.

## Credits
Kryojenik's LTN Combinator; got me started with a lot of the basics and a couple bits are still mostly copied from there.
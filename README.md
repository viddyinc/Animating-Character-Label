Animating-Character-Label
=========================

UILabel-like view to randomly fade in each character of string

This is alpha version, so it is not direct substitute for UILabel yet.
For example, sizeToFit method is missing.

Internally it uses UITextView to draw.

Animating label uses gcd to calculate and prepare for actual fade in of characters, so if used in dequeue-able cells, make sure to call "prepareToReuse:" method on the label for clean up. Else you will end up with multiple strings drawn to the label. 

TODO:
1) investigate CoreText/TextKit for backstore.
2) Update to be UILabel (or UITextView minus edit?) drop in replacement.

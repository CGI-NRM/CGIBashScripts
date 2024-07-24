import sys

if len(sys.argv) > 1:
    in_seq = sys.argv[1]
else:
    in_seq = ''

def rev_comp(sequence): # Function that takes a sequence (a string), upper or lower case, and reverse-complements it
    sequence = sequence[::-1] # Reverse the sequence
    new_seq = "" # Initialize the new sequence
    for nucleotide in sequence: # For every nucleotide/character in the sequence
        if nucleotide == "A" or nucleotide == "a":
            nucleotide = nucleotide.replace("A","T")
            nucleotide = nucleotide.replace("a","t")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "C" or nucleotide == "c":
            nucleotide = nucleotide.replace("C","G")
            nucleotide = nucleotide.replace("c","g")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "G" or nucleotide == "g":
            nucleotide = nucleotide.replace("G","C")
            nucleotide = nucleotide.replace("g","c")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "T" or nucleotide == "t" or nucleotide == "U" or nucleotide == "u":
            nucleotide = nucleotide.replace("T","A")
            nucleotide = nucleotide.replace("t","a")
            nucleotide = nucleotide.replace("U","A")
            nucleotide = nucleotide.replace("u","a")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "M" or nucleotide == "m":
            nucleotide = nucleotide.replace("M","K")
            nucleotide = nucleotide.replace("m","k")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "R" or nucleotide == "r":
            nucleotide = nucleotide.replace("R","Y")
            nucleotide = nucleotide.replace("r","y")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "Y" or nucleotide == "y":
            nucleotide = nucleotide.replace("Y","R")
            nucleotide = nucleotide.replace("y","r")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "K" or nucleotide == "k":
            nucleotide = nucleotide.replace("K","M")
            nucleotide = nucleotide.replace("k","m")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "V" or nucleotide == "v":
            nucleotide = nucleotide.replace("V","B")
            nucleotide = nucleotide.replace("v","b")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "H" or nucleotide == "h":
            nucleotide = nucleotide.replace("H","D")
            nucleotide = nucleotide.replace("h","d")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "D" or nucleotide == "d":
            nucleotide = nucleotide.replace("D","H")
            nucleotide = nucleotide.replace("d","h")
            new_seq = new_seq + nucleotide
            continue
        elif nucleotide == "B" or nucleotide == "b":
            nucleotide = nucleotide.replace("B","V")
            nucleotide = nucleotide.replace("b","v")
            new_seq = new_seq + nucleotide
            continue
        else:
            new_seq = new_seq + nucleotide
            continue
    return new_seq # Return the new sequence

print(rev_comp(in_seq))

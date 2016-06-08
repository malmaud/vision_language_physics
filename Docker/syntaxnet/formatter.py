import csv
import StringIO

def format(sentence):
    buffer = StringIO.StringIO()
    writer = csv.writer(buffer)
    for token in sentence.token:
        writer.writerow([token.word, token.start, token.end, token.head, token.tag, token.category, token.label, token.break_level])
    buffer.seek(0)
    return buffer.read()

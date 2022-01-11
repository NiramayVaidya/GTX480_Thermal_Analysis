import sys

def main():
    filename = sys.argv[1]
    lines = []
    with open(filename, 'r+') as f:
        lines = f.readlines()
        for i in range(0, len(lines)):
            line = lines[i].split('\t')
            for j in range(1, len(line)):
                line[j] = str(round(float(line[j]) / 1000, 7))
            lines[i] = '\t'.join(line)
        # f.seek(0)
        # lines = [lines[i] + '\n' if i != len(lines) - 1 else lines[i] for i in range(0, len(lines))]
        lines = [lines[i] + '\n' if i != len(lines) - 1 else lines[i] + '\n\n' for i in range(0, len(lines))]
        # f.writelines(lines)
        # f.truncate()
    filename = sys.argv[2]
    with open(filename, 'a+') as f:
        f.seek(0)
        f.truncate()
        f.writelines(lines)

if __name__ == '__main__':
    main()

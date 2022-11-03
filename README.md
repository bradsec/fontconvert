# FONTCONVERT

A bash shell script for batch conversion of font files using fontforge. Supports both TrueType Font (TTF) and OpenType Font (OTF). Convert from either format. 

`.ttf` files will be converted to `.otf`  
`.otf` files will be converted to `.ttf`

By default new converted file names will be changed to lowercase and cleaned up to include only alpha-numeric characters. If you don't want the filename changed set `config[cleanName]=false` in the config array.  

Any font files which cannot be converted due to being invalid, bad or corrupt files will be moved to the configured `config[badDir]` directory which by default is `./bad`.

To enable a recursive search of the source directory increase the `config[maxDepth]` from 1.

### Usage
```terminal
FONTCONVERT (for use with fontforge)

Usage:

    Run script using: ./fontconvert.sh or bash fontconvert.sh

    Source files to be converted need to be in [.../fontconvert/src].

    .ttf files will be converted to .otf
    .otf files will be converted to .ttf

    New files will be saved in [.../fontconvert/dst].

    Bad or corrupt source files will be moved to [.../fontconvert/bad].
```

### Script Setup

1. Clone the repo
```terminal
cd ~
git clone https://github.com/bradsec/fontconvert.git
cd fontcovert
```
2. Make script executable
```terminal
chmod +x fontconvert.sh
```
3. **Copy fonts to be converted into the `/fontconvert/src` directory.**

4. Run the script
```terminal
./fontconvert.sh
```

The files will be converted and saved in the `/fontconvert/dst` directory.

### Requirements

The fontforge package must be installed. Visit https://fontforge.org or https://github.com/fontforge/fontforge for more information.

- Debian/Ubuntu Linux install
```terminal
sudo apt install fontforge
```
- macOS install (using homebrew)
```terminal
brew install fontforge
```
- macOS may also require bash to be upgraded if running < bash v4
```terminal
brew install bash
exec bash
```


### Troubleshooting

Corrupt or bad font files will be prefixed by [FAIL]. The script will continue to process any remaining files. To view the full error of a failed file try running fontforge manually on the problem font file with the command below. Change the last two names `fontin.ttf` and `fontout.otf` to the applicable file name.

```terminal
fontforge -lang=ff -c 'Open($1); Generate($2); Close();' fontin.ttf fontout.otf
```




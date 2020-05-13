# Time Switch Data Extractor

## Usage
Run tsde with the input data filename, configuration JSON filename (one is supplied with the code) and the output directory. If all is well, the data will be extracted shortly.

## Compilation
The easiest way is to install the Digital Mars D compiler (DMD) which should install the Dub dependency\build tool along with. Then type "dub" to create a binary from the sources. Use "dub generate visuald" if you want to create a Visual Studio + Visual D project file to work with.

## Configuration
The included JSON configuration should serve as a good example for other versions. The name JSON files have been omitted but can be created easily with readily available information. Without the name JSON files placeholder names will be used, making some of the data harder to understand but essentially the same.

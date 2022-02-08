# L.E.`mount`

A front-end to `mount`(8) which makes mounting disks something more elegant.  
It's loosely inspired in how Solaris used to manage disks back in the day, but implemented in it's own way.  
This is just a prototype as a proof-of-concept. I intend to write the final `lemount` in Go.  

## Features

I've made it for mouting disks in a more elegant way.  
Tired of creating multiple directories in `/` and `/mnt`, i created this script.  
Instead of mounting `/dev/sdXY` in `/mnt/diskY`, you can mount it in `/dsk/Yp` (`p` corresponds to the postfix, i will explain it later).  

|![img/Screenshot_2021-07-14_09-16-21.png](img/Screenshot_2021-07-14_09-16-21.png) |
|:--:|
| *A demonstration using a NTFS-formatted physical disk.* |

## Usage/Examples

Let's suppose, hypothetically speaking, that i have a virtual disk image, i will call it `DISK.img` and i want to mount it.  
I first will simply expose the disk to the system, using `losetup`(8).  
Then, i will run `lemount`.  
At the first question, which is "Which disk do you want to mount?", will respond it with my disk identifier that i probabily saw when it listed my disk.  
In this case, it's `loop0`.  
Then, it will question me about what type of media it is. Is it a disk? a USB? a CD-ROM Drive?  
Since it's a disk, i can answer with `dsk`.  
After this, it will mount my disk at `/dsk/0v`; in which `dsk` is the type, `0` is the disk idenfier (in this case, as there weren't any other disks mounted before, it will be `0`) and `v` is the postfix, it indicates (`v`)irtual.  

## Get L.E.`mount`

Releases and VCS snapshots can be found at `get.pindorama.dob.jp`.  
[*http://get.pindorama.dob.jp/lemount*](https://get.pindorama.dob.jp/lemount)  

## TODO

- Portabilize it more;
- May mount virtual disks (`loopX`) without needing `losetup`(8);
- Rewrite it in Go.

## Used By

I've made thinking in it's usage at Copacabana OpenLinux, but in fact you can use it in any Linux box.

## Acknowledgements

Thanks CallTheSamu, ArthurBacci, Sevla and Baux for suggesting names and helping me polishing the idea.

## License

The Caldera License.

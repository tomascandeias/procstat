# ProcStat
Bash script that shows statistics of the memory used and how much I/O all or a portion of the processes that are running are using.

## Description

This script allows you to visualize how much memory a process is using in total, how much physical memory a process is occupying, the total number of bytes of I/O that a process wrote/read and also the rate of I/O corresponding to the last s seconds.

## Getting Started

### Dependencies

The only requirement is having Linux installed on your machine  

### Executing program

Set execute permission on procstat.sh script using chmod command
```
chmod +x procstat.sh
```

Sort by:  
* -m MEMORY  
* -t RSS  
* -d RATER  
* -w RATEW  
* -r REVERSE  

Examples of execution are included in "89123_89285.pdf" on page 9 and 10

```
./procstat.sh [-c <reg exp>] [-p <number of processes>] [-u <user>] [-m -t -d -w -r]
```

## Help

Advise for common problems or issues, run the script with no arguments.
```
./procstat.sh
```

## Authors

[@tomascandeias](https://www.linkedin.com/in/tomascandeias/)  
[@afonsoboto](https://www.linkedin.com/in/afonso-boto/)

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

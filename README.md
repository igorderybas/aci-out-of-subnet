**ACI Out of subnet EP check**

A small script that checks ACI Remote EPs (XRs) against subnets in a VRF. 
It's useful for validation before enabling Global Subnet Check setting. 
Run it on APIC CLI, no pre-requisites, it's a simple bash script that does 3 moquery and parses the outputs.

Limitations:
 - The script focusing on checkng only Remote EPs, Local learned EPs are ignored.
 - The script work only for IPv4 EPs

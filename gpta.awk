#!  /usr/bin/gawk -f

# Use this with macosx (gawk should be installed, brew install gawk)
# /usr/local/bin/gawk -f

# Changelog: git is used (use: git log)
# 2022-08-18 christian.lanconelli@ext.ec.europa.eu
# BSRN Averaging program based on Roesch et al. 2011, and the timeAverage.s.v5.awk script
# See readme.txt for older changelog

BEGIN {
FS=","
sysoffset = 3600*strftime("%k",0)
ERRMESS = "Correct use: TZ=UTC <program_name.awk> --assign INTT=value[sec] [ --assign OFF=value[sec] ] --assign SITE=site [-v QC=M2]"
headexists = 0
# Print a Welcome message 
print "# gpta v0.1 - 2022"
print "# A general purpose flexible time averaging program based on timeAverage.s.v5.awk"
print "# Hint: grep -n #_Date <filename> to identify the starting line of the data section"

# INTT intervallo in secondi su cui eseguire la media
# sysoffset should be set to zero (TZ=UTC ./program ...) to avoid problems witht the DST

if (INTT == 0 || sysoffset!=0) {
	print ERRMESS
	exit 1
}

print "# Averaging time", INTT,"seconds with offset", OFF

# Lista delle configurazioni
if (SITE == "bsrnnf") {
    # bsrnnf is a permissive extremes configuration [-990:1,000,000]
	# BSRN RAW data averages (as called by "raw_system_0.2_alpha_server.sh")
	headarray="date:time:swd03:dirn:dif:lwd03:temp2m:rh:press:swu03:lwu03:swu10:lwu10:swu30:lwu30:lwd03_signal:lwd03_td:lwd03_tb:lwu03_signal:lwu03_tb:lwu03_td:lwd10_signal:lwd10_td:lwd10_tb:lwu10_signal:lwu10_td:lwu10_tb:lwd30_signal:lwd30_td:lwd30_tb:lwu30_signal:lwu30_td:lwu30_tb:sza"
    # Replaced minimum:  all -> -990
    # Replaced maximum:  all -> 1.E6
	minarray="::-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990:-990"
	maxarray="::1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6:1.E6"
    
}	

else if (SITE == "bsrn") {
	# BSRN RAW data averages (as called by "raw_system_0.2_alpha_server.sh")
	headarray="date:time:swd03:dirn:dif:lwd03:temp2m:rh:press:swu03:lwu03:swu10:lwu10:swu30:lwu30:lwd03_signal:lwd03_td:lwd03_tb:lwu03_signal:lwu03_tb:lwu03_td:lwd10_signal:lwd10_td:lwd10_tb:lwu10_signal:lwu10_td:lwu10_tb:lwd30_signal:lwd30_td:lwd30_tb:lwu30_signal:lwu30_td:lwu30_tb:sza"
	minarray="::-4:-4:-4:40:-90:0:500:-4:40:-4:40:-4:40:-500:-90:-90:-500:-90:-90:-500:-90:-90:-500:-90:-90:-500:-90:-90:-500:-90:-90:0"
	# Note: szamax has a value set to 99 because this is th emaximum value 
	#       reported by the BSRN-TooBox. Daily averages of the SZA then do 
	#       not make sense!
	maxarray="::1500:1500:1500:700:60:100:1100:1500:700:1500:700:1500:700:50:60:60:50:60:60:50:60:60:50:60:60:50:60:60:50:60:60:99"

}
else { 
	print ERRMESS
	print "SITE variable should be set to one of the following option with <-v SITE=...> on the command line"
	print "bsrn:bsrnnf"
	exit 1
}

# From version 4
split (minarray,min,":")
split (maxarray,max,":")
split (headarray,head,":")

# For version 5 only!
for (i in head) { 
	# Append to min and max arrays element indexed associatively (see getheader.awk example)
	# print head[i]
	min[head[i]] = min[i]
	max[head[i]] = max[i]
	inf[head[i]] =  1.E6
	sup[head[i]] = -1.E6
}
}

# === Main section ===
# This section is executed line-by-line as AWK generally does

$0 ~ /date/ {
#
# This section identify the header line which should always contain the keyword "date"
# and initialize some variables performing some configuration.
#
# Initialize the names array with indexing the name of the columns.
LC = NF
split($0,names,",")
print "# Number of fields in the input files:", LC
print "# Column Name min max (Note: min and max are not used if -v QC= is set)"
for (i in names) print "#", i,names[i],min[names[i]],max[names[i]]

# Set a default onames1string
if (onames1string == "") onames1string="swd03,lwd03"

split(onames1string,onames,",")  # define the array of index to be used in the output section
print "# Reporting averages for [", onames1string, "]" 
printf("#_Date Time")
for (i in onames) printf(" %s_avr %s_sig %s_min %s_max %s_n",onames[i],onames[i],onames[i],onames[i],onames[i])
print ""

headexists = 1                        # Set a control variable indicating that a header was scanned.
}

# Data block accumulations
$0 !~ /^#/ && $0 ~/^[12]/ && headexists==1 {

# Getting the content of the current record in the array "values"
# split($0,value,",") 
for (i = 1; i<=NF; i++) { value[names[i]] = $i }

# print ">>> valori:", NR 
# for ( i in value ) { print i,value[i] }

Y=substr($1,1,4) # anno
m=substr($1,6,2) # mese
d=substr($1,9,2) # giorno

H=substr($2,1,2) # ora
M=substr($2,4,2) # minuto
S=substr($2,7,2) # secondo

string = sprintf("%04d %2d %2d %2d %2d %2d %2d",Y,m,d,H,M,S,0) # http://www.gnu.org/manual/gawk/html_node/String-Functions.html#String-Functions
seconds = mktime(string)                                       # from the Epoch: http://www.gnu.org/manual/gawk/html_node/Time-Functions.html#Time-Functions

# DBUG: print string
# DBUG: print seconds

# Controllo che la riga attuale non sia relativa ad un periodo maggiore della lettura aspettata
# La lettura aspettata sara' l'ultima scrittura piu' l'INTT ...

# Il tempo alla fine del periodo corrente e' selezionato in base al tempo di integrazione
# finche' questo tempo non cambia aggiungo valori allo stack, non appena cambia scrivo i dati in output
# e reinizializzo lo stack con i valori correnti
# Esso vale in secondi:

target_time = (int(seconds/INTT)+1)*INTT                    # v3
# target_time=( int ( (seconds+OFF) / INTT) + 1) * INTT    # v4+

# DBUG: print target_time, NR, ptarget_time

# if (NR==1) ptarget_time=target_time               # vecchia inizializzazione (problemi se prima ci sono record che iniziano con #, non e' NR==1)
if (ptarget_time=="") { ptarget_time=target_time }  # inizializzazione

if (target_time > ptarget_time)
{
	# TODO: Fill the output with -998 empty periods (real gaps)
	
	# We reached the following averaging period so that we can print the output and reset the arrays
	# to the current values
	printoutput(ptarget_time-INTT/2-OFF)
	
	# Reset the values, then associates the values in the stack if they are valid
	for ( i in names ) {
		idx = names[i]
		sum[idx]  = 0
		sum2[idx] = 0
		inf[idx]  =  1E6
		sup[idx]  = -1E6
		N[idx] = 0
	}	
	
	# And the number of GAPS until the new time 
	# DBUG: print $1,$2, target_time, ptarget_time, target_time - ptarget_time
	ngaps = ( target_time - ptarget_time ) / INTT - 1
	# if ( ( target_time - ptarget_time ) > INTT ) print "Gap here, will print the ", ngaps
	for (j = 1; j<=ngaps ; j++) {
		# ctime = strftime("%Y-%m-%d %H:%M:%S", ptarget_time + j*INTT/2 - OFF )
		ctime = ptarget_time + j*INTT/2 - OFF
		printoutput(ctime)
	}
	
	# Set the new target_time
	ptarget_time = target_time
	
}

# Here we are in the same target time accumulating period  
# DBUG: print seconds, target_time, strftime("%Y-%m-%d %H:%M:%S", seconds), strftime("%Y-%m-%d %H:%M:%S", ptarget_time), sysoffset

for (i in names) {
	
	# skipping the date and time names (expected to be at position 1 and 2, names[1]="date" and
	# names[2]="time", respectively)
	if (i+0 >= 3) {
		idx   = names[i]
		# Accumulating only for oname
		# print "DBUG0:", idx, index(onames1string,idx)
		
		if ( index(onames1string,idx) > 0 ) {
			idxqc = sprintf("%s%s",idx, "qc")
			flags = bits2strr(value[idxqc])  # e.g. 62 => 111110
			# print "DBUG1:", idx, idxqc, value[idx], value[idxqc], flags
			
			if ($i == "NaN" || $i == "NAN" || $i == "nan" || $i == "" ) $i = -999   # Manage empty columns, NaN etc ... columns
			
			# DBUG: print i,names[i],$i
		
			# Check that the value is within the boundaries defined by [min[idx]:max[idx]] and accummulate
			# TODO: include the possibility to skip the accummulation if the current value is flagged
			#       if the current value is  
			
			if ( QC == "M2" ) {
				
#               Build individual flags accordingly to BSRN-Toolbox:
# 				Bit position, Decimal representation, substring position, Meaning
#               0 	1 	6 Measurement falls below the physically possible limit
#               1 	2 	5 Measurement exceeds the physically possible limit
#               2 	4 	4 Measurement falls below the extremely rare limit
#               3 	8 	3 Measurement exceeds the extremely rare limit
#               4 	16 	2 Compared with a corresponding measurement the measurement is too low
#               5 	32 	1 Compared with a corresponding measurement the measurement is too high
			
				pplflginf = substr(flags,6,1)
				pplflgsup = substr(flags,5,1)
				erlflginf = substr(flags,4,1)
				erlflgsup = substr(flags,3,1)
				cmpflglow = substr(flags,2,1)
				cmpflghig = substr(flags,1,1)
				
				# print "DBUG2:", pplflginf, pplflgsup, erlflginf, erlflgsup, cmpflglow, cmpflghig
				if ( erlflginf == 0 && erlflgsup == 0 ) {
					sum[idx] += value[idx]
					sum2[idx] += value[idx] * value[idx]
					# Defining the min and max values for the current averaging period
					if ( $i<inf[idx] ) inf[idx] = value[idx]
					if ( $i>sup[idx] ) sup[idx] = value[idx]
					# The number of elements of the current averaging period
					N[idx] += 1
				}
			}
			else if (min[idx] <= value[idx] && value[idx] <= max[idx])	{
				sum[idx] += value[idx]
				sum2[idx] += value[idx] * value[idx]
				# Defining the min and max values for the current averaging period
				if ( $i<inf[idx] ) inf[idx] = value[idx]
				if ( $i>sup[idx] ) sup[idx] = value[idx]
				# The number of elements of the current averaging period
				N[idx] += 1
			}
		}
	}
}

}

END {
	
	if (headexists == 0) {printf("No header encoutered") ; exit 2 }
	printoutput(ptarget_time-INTT/2-OFF)
	if (INT==0) exit 1
    print "# Failures=" trackfail, "; Tot length (NR/interval)=" NR/INTT , "; % fail=" trackfail/(NR/INTT), "; INTT (sec)=" INTT
    print "# End of averaging section"
	print "# File:", FILENAME
	print "# Processed on ", strftime()
}

# List of functions


function bits2str(bits, data, mask) {
# BSRN-Toolbox report quality control flags as a 2^6 bit 
# https://www.gnu.org/software/gawk/manual/html_node/Bitwise-Functions.html
# MSB---LSB
    if (bits == 0)
        return "0"

    mask = 1
    for (; bits != 0; bits = rshift(bits, 1))
        data = (and(bits, mask) ? "1" : "0") data

    while ((length(data) % 6) != 0)
        data = "0" data

    return data
}

function bits2strr(x){
	# Tweked for a 6 bit number (0-63) as BSRN-Toolbox report
	b = ""
	y = int(x)
	while (y > 0) {
		# printf "%2s | %1s\n", y, b = (y%2)b
		b = (y%2)b
		y = int(y/2)
	}
	return sprintf("%06d",b)
}

function printoutput(t){
# Scrittura (by default the middle of the period, but can be changed to end or begin by setting the offset)
 	printf "%s ", strftime("%Y-%m-%d %H:%M:%S ", t)   # v4+
#	printf "%s ", strftime("%Y-%m-%d %H:%M:%S ", ptarget_time-INTT)   # v4+
	for (i in onames) {
		idx = onames[i]
		if (N[idx] > 1) {
			printf("%7.1f%7.1f%7.1f%7.1f%4i ", avr = sum[idx]/N[idx], 
											   sig = sqrt (sum2[idx] / N[idx] - (avr ** 2)), inf[idx],sup[idx],N[idx])
		}
		else if ( N[idx] == 1 ) printf("%7.1f%7.1f%7.1f%7.1f%4i ", sum[idx], sig = 0., inf[idx],sup[idx],N[idx])
		else printf("%7.1f%7.1f%7.1f%7.1f%4d ", -999.,-99.9, -999.,-999.,-9)
	}
	printf("\n")
}	


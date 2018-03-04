
import sys, os, glob, fnmatch, shutil
import zipfile, binascii

############# MAIN PATH #####################
main = sys.argv[1]
#############################################

#_directoriees
indir  = main   + "/Raw/DEEDS/AKTES"
outdir = main   + "/Generated/DEEDS"
temp   = outdir + "/temp/"

#############################################
# Part 1: Extract All transactions lines.   #
#############################################

#_create_temp_folder
shutil.rmtree(temp, True)
os.makedirs(temp)

#_list_all_zip_files 
allzips = [os.path.join(dirpath, f)
    for dirpath, dirnames, files in os.walk(indir)
    for f in fnmatch.filter(files, '*.zip')]

#_unzip_into_temp_folder
for eachzip in allzips:
    with zipfile.ZipFile(eachzip, 'r') as z:
        subfiles = z.namelist()
        for subfile in subfiles:
            base = os.path.basename(subfile)
            if base :
                unzipped = open(temp + base, 'w')
                unzipped.write(z.read(subfile))
                unzipped.close()

#_list_all__transaction_z_files 
allzips = [os.path.join(dirpath, f)
    for dirpath, dirnames, files in os.walk(indir)
    for f in fnmatch.filter(files, 'TRAN*.TXT.Z')]
allzips2 = [os.path.join(dirpath, f)
    for dirpath, dirnames, files in os.walk(indir)
    for f in fnmatch.filter(files, '[Aa][Kk][Tt][Ee][Ss]*.TXT.Z')]
allzips.extend(allzips2)

#_unzip_into_temp_folder
for eachzip in allzips:
    os.system('7z x "' + eachzip + '" -o'+temp+' *.TXT -r -y')

#_list_all_txt_files
alltxt = [os.path.join(dirpath, f)
    for dirpath, dirnames, files in os.walk(indir)
    for f in fnmatch.filter(files, '*.[Tt][Xx][Tt]')]

#_copy_all_txt_to_temp_folder
for txt in alltxt:
    shutil.copy(txt,temp)

## Begin Cleaning

#_make_list
txts = glob.glob(temp+"*")

for txt in txts:

    #_skip_directories
    if os.path.isdir(txt):
        continue

    #_delete_empty_files
    size = os.path.getsize(txt)
    if int(size) <1:
        os.remove(txt)
        continue

    #_read_first_line
    with open(txt, 'r') as f:
        first_char = f.readline()[0]
    
    #_delete_useless_files
    if not first_char.isdigit():
        os.remove(txt)
        continue

    #_delete_duplicate_files
    if txt[-7:-4]=="(1)":
        os.remove(txt)
        continue

## End Cleaning

#_consolidate_into_single_txt
txts = glob.glob(temp+"*.*")
with open(outdir+"/ALL.txt", "wb+") as outfile:
    for txt in txts:
        with open(txt, "rb") as infile:
            outfile.write(infile.read())

#_filter_non_transactions:
with open(outdir+"/ALL.txt", "rb") as infile:
    with open(outdir+"/AKTES.txt", "wb+") as outfile:
        lines = infile.readlines()
        for line in lines:
            if line[702:703] in ["E","F","U","H"]:
                outfile.write(line)
os.remove(outdir+"/ALL.txt")

#_clean_up
shutil.rmtree(temp, True)

##############################################
# Part 2: Extract township_2_CSG21digitkeys  #
##############################################

#_create_temp_folder
shutil.rmtree(temp, True)
os.makedirs(temp)

#_list_all_z_files 
allzips = [os.path.join(dirpath, f)
    for dirpath, dirnames, files in os.walk(indir)
    for f in fnmatch.filter(files, '*.TXT.Z')]

#_unzip_into_temp_folder
for eachzip in allzips:
    if os.path.basename(eachzip)[:2] in ['ST','TR','AK','Ak','ak','aK']:
        continue
    os.system('7z x "' + eachzip + '" -o'+temp+' *.TXT -r -y')

#_clean_and_consolidate_lines
farms = glob.glob(temp+"FARM*")
holds = glob.glob(temp+"HOLD*")
towns = glob.glob(temp+"TOWN*")
txts  = [farms,holds,towns]
titls = ["/FARMS.txt","/HOLDINGS.txt","/TOWNS.txt"]
for i in range(0,3):
    with open(outdir+titls[i], "wb+") as outfile:
        with open(txts[i][0],'r') as infile: outfile.write(infile.readlines()[0][:250].strip()+'\n') 
        for txt in txts[i]:
            with open(txt, 'r') as infile:
                lines =  infile.readlines()[1:]
                for line in lines:
                    outfile.write(line[:250].strip()+'\n')

#_clean_up
shutil.rmtree(temp, True)


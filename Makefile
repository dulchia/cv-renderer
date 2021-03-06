# Options: br de fr it nl uk us es
country = fr

# Options: letter for country=us, a4 for others
papersize = a4

html_style = olivier/$(country)-html.xsl
text_style = olivier/$(country)-text.xsl
fo_style = olivier/$(country)-$(papersize).xsl

out_dir = out
tmp_dir = tmp
upload_dir = upload

# web fonts to copy to output
# source
in_fonts_dir = Bergamo-Std-fontfacekit
in_fonts = $(wildcard $(in_fonts_dir)/*.eot $(in_fonts_dir)/*.svg $(in_fonts_dir)/*.ttf $(in_fonts_dir)/*.woff)
# destination
out_fonts_dir = $(out_dir)/fonts
out_fonts = $(patsubst $(in_fonts_dir)/%,$(out_fonts_dir)/%,$(in_fonts))

common_deps = olivier/params.xsl olivier/fr.xsl olivier/uk.xsl
pdf_deps = $(common_deps) olivier/fo.xsl olivier/fr-a4.xsl olivier/uk-a4.xsl
html_deps = $(common_deps) olivier/html.xsl olivier/fr-html.xsl olivier/uk-html.xsl $(out_dir)/style.css $(out_fonts)
text_deps = $(common_deps) olivier/text.xsl olivier/fr-text.xsl olivier/uk-text.xsl

# final names (online)
fn_en_pdf = Olivier\ Scherler\ CV\ English.pdf
fn_en_html = Olivier\ Scherler\ CV\ English.html
fn_en_txt = Olivier\ Scherler\ CV\ English.txt
fn_fr_pdf = Olivier\ Scherler\ CV\ Français.pdf
fn_fr_html = Olivier\ Scherler\ CV\ Français.html
fn_fr_txt = Olivier\ Scherler\ CV\ Français.txt

fo_flags = -c fop.xconf

#------------------------------------------------------------------------------
# Processing software
#------------------------------------------------------------------------------
make = make

MY_FOP_HOME=fop-1.1
MY_CLASSPATH=resume-1_5_1/java/xmlresume-filter.jar:$(FOP_HOME)/build/fop.jar:$(FOP_HOME)/lib/*:$(CLASSPATH)

xsl_proc = java -cp $(MY_CLASSPATH) org.apache.xalan.xslt.Process $(xsl_flags) -in $(in) -xsl $(xsl) -out $(out)
#xsl_proc = java -cp $(MY_CLASSPATH) com.icl.saxon.StyleSheet $(xsl_flags) -o $(out) $(in) $(xsl) $(xsl_params)

xmllint = xmllint --format --output $(out) $(out)

pdf_proc = $(FOP_HOME)/fop $(fo_flags) -fo $(in) -pdf $(out)
#pdf_proc = ~/bin/xep/run.sh $(fo_flags) $(in) $(out)

# RTF generation currently requires you download a separate, closed source jar 
# file and add it to your java classpath: 	
# http://www.xmlmind.com/foconverter/downloadperso.shtml
rtf_proc = java -cp $(MY_CLASSPATH) com.xmlmind.fo.converter.Driver $(in) $(out)
#rtf_proc = java -cp $(MY_CLASSPATH) ch.codeconsult.jfor.main.CmdLineConverter $(in) $(out)

# Element filtering allows you to create targeted resumes.  
# You can create your own targets; just specify them in your resume.xml 
# file with the "targets" attribute.  In this example, the foodservice
# AND carpentry elements will be included in the output, but not the 
# elements targeted to other jobs.  Untargeted elements (those with no 
# "targets" attribute) are always included.  
# Take a look at example2.xml and try changing the filter targets to get a 
# feel for how the filter works.
filter_targets = test
filter_proc = java -cp $(MY_CLASSPATH) net.sourceforge.xmlresume.filter.Filter -in $(in) -out $(out) $(filter_targets)

#------------------------------------------------------------------------------
# End configurable parameters
#------------------------------------------------------------------------------

.PHONY: all html text pdf rtf clean list-fonts upload_files sync

# otherwise Make will remove them after running as it considers them intermediate
.SECONDARY: $(out_fonts)

default: pdf
all: html text pdf

# formats
html: $(out_dir)/cv-en.html $(out_dir)/cv-fr.html
text: $(out_dir)/cv-en.txt $(out_dir)/cv-fr.txt
pdf: $(out_dir)/cv-en.pdf $(out_dir)/cv-fr.pdf
rtf: $(out_dir)/cv-en.rtf $(out_dir)/cv-fr.rtf

# fr
$(tmp_dir)/cv-en-filtered.xml: filter_targets = en abroad
$(tmp_dir)/cv-en.fo: country = uk
$(out_dir)/cv-en.pdf: country = uk
$(out_dir)/cv-en.txt: country = uk
$(out_dir)/cv-en.html: country = uk

# en
$(tmp_dir)/cv-fr-filtered.xml: filter_targets = fr abroad
$(tmp_dir)/cv-fr.fo: country = fr
$(out_dir)/cv-fr.pdf: country = fr
$(out_dir)/cv-fr.txt: country = fr
$(out_dir)/cv-fr.html: country = fr

clean: clean-cv-fr clean-cv-en

clean-%:
	rm -f $(out_dir)/$*.html
	rm -f $(out_dir)/$*.txt
	rm -f $(tmp_dir)/$*.fo
	rm -f $(out_dir)/$*.pdf
	rm -f $(out_dir)/$*.rtf
	rm -f $(tmp_dir)/$*-filtered.xml

# html
$(out_dir)/%.html: in = $(tmp_dir)/$*-filtered.xml
$(out_dir)/%.html: out = $(out_dir)/$*.html
$(out_dir)/%.html: xsl = $(html_style)
$(out_dir)/%.html: $(out_dir) $(tmp_dir)/%-filtered.xml $(html_deps)
	$(xsl_proc)

# txt
$(out_dir)/%.txt: in = $(tmp_dir)/$*-filtered.xml
$(out_dir)/%.txt: out = $(out_dir)/$*.txt
$(out_dir)/%.txt: xsl = $(text_style)
$(out_dir)/%.txt: $(out_dir) $(tmp_dir)/%-filtered.xml $(text_deps)
	$(xsl_proc)

# fo
$(tmp_dir)/%.fo: in = $(tmp_dir)/$*-filtered.xml
$(tmp_dir)/%.fo: out = $(tmp_dir)/$*.fo
$(tmp_dir)/%.fo: xsl = $(fo_style)
$(tmp_dir)/%.fo: $(tmp_dir)/%-filtered.xml $(pdf_deps)
	$(xsl_proc)

# pdf
$(out_dir)/%.pdf: in = $(tmp_dir)/$*.fo
$(out_dir)/%.pdf: out = $(out_dir)/$*.pdf
$(out_dir)/%.pdf: $(out_dir) $(tmp_dir)/%.fo
	$(pdf_proc)

# rtf
$(out_dir)/%.rtf: in = $(tmp_dir)/$*.fo
$(out_dir)/%.rtf: out = $(out_dir)/$*.rtf
$(out_dir)/%.rtf: $(out_dir) $(tmp_dir)/%.fo
	$(rtf_proc)

# filter
$(tmp_dir)/%-filtered.xml: in = cv-multilingual.xml
$(tmp_dir)/%-filtered.xml: out = $(tmp_dir)/$*-filtered.xml
$(tmp_dir)/%-filtered.xml: $(tmp_dir) cv-multilingual.xml
	$(filter_proc)

# copy CSS file
$(out_dir)/style.css: $(out_dir) style.css
	cp style.css $(out_dir)/style.css

# make out directory
$(out_dir):
	mkdir -p $(out_dir)

# make tmp directory
$(tmp_dir):
	mkdir -p $(tmp_dir)

# make upload directory
$(upload_dir):
	mkdir -p $(upload_dir)

# make output fonts directory
$(out_fonts_dir):
	mkdir -p $(out_fonts_dir)

# copy web fonts
$(out_fonts_dir)/%: $(out_fonts_dir) $(in_fonts_dir)/%
	cp $(in_fonts_dir)/$* $(out_fonts_dir)/$*

# list fonts available to FOP
list-fonts:
	java -cp $(MY_CLASSPATH) org.apache.fop.tools.fontlist.FontListMain -c fop.xconf

# remove referees from xml
$(out_dir)/cv.xml: cv-multilingual.xml deref.php
	php deref.php cv-multilingual.xml out/cv.xml

# copy online files to upload dir
upload_files: $(upload_dir) $(upload_dir)/$(fn_en_pdf) $(upload_dir)/$(fn_fr_pdf) $(upload_dir)/$(fn_en_txt) $(upload_dir)/$(fn_fr_txt) $(upload_dir)/$(fn_en_html) $(upload_dir)/$(fn_fr_html) $(upload_dir)/Source\ CV.xml

# English pdf
$(upload_dir)/$(fn_en_pdf): src = cv-en.pdf
$(upload_dir)/$(fn_en_pdf): $(out_dir)/cv-en.pdf
# French pdf
$(upload_dir)/$(fn_fr_pdf): src = cv-fr.pdf
$(upload_dir)/$(fn_fr_pdf): $(out_dir)/cv-fr.pdf
# English txt
$(upload_dir)/$(fn_en_txt): src = cv-en.txt
$(upload_dir)/$(fn_en_txt): $(out_dir)/cv-en.txt
# French txt
$(upload_dir)/$(fn_fr_txt): src = cv-fr.txt
$(upload_dir)/$(fn_fr_txt): $(out_dir)/cv-fr.txt
# English html
$(upload_dir)/$(fn_en_html): src = cv-en.html
$(upload_dir)/$(fn_en_html): $(out_dir)/cv-en.html
# French html
$(upload_dir)/$(fn_fr_html): src = cv-fr.html
$(upload_dir)/$(fn_fr_html): $(out_dir)/cv-fr.html
# Source xml
$(upload_dir)/Source\ CV.xml: src = cv.xml
$(upload_dir)/Source\ CV.xml: $(out_dir)/cv.xml

# upload copy rule
$(upload_dir)/%: $(src)
	cp $(out_dir)/$(src) '$(upload_dir)/$*'

# upload
sync: upload_files $(out_fonts) $(out_dir)/style.css
	# main files
	rsync -avz upload/ its:domains/olivier.ithink.ch/www/cv/_public/
	# fonts
	rsync -avz out/fonts/ its:domains/olivier.ithink.ch/www/cv/fonts/
	# css
	scp out/style.css its:domains/olivier.ithink.ch/www/cv/style.css

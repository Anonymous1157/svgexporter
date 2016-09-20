# Makefile for automatic export, optimization, and packing of SVG art

# CHANGELOG:
# V5
# - Removed large number of comments describing outdated functionality
# - Added documentation on how to change build settings with .mk files
# - Refactored recipes to use variables extensively; nothing is hard-coded
# - Refactored redundant recipes to use function calls
# V4
# - Refactored recipes to use variables for program names and options
# - Added support for overriding project settings in an external makefile
# - Changed work file directory structure to use one subfolder for all
#    temporary files
# - Removed redundant recipe using second-expansion
# V3
# - Rewrote recipes to give beautiful output
# - Added support for exporting GIF or MP4 animations
# - Added support for gracefully handling symlinks between source files
#    (Useful for repeating frames in animations)
# - Retconned changelog notes for older versions
# V2
# - Resolved issue where all targets were always run because directories
#    have their dates updated every time they are accessed
# - Improved speed by instructing make not to check for targets to build
#    the usual C/C++ source dependencies, like Yacc parsers
# - Changed all variable definitions to immediate assignments (:=)
#    so they are only run once right away
# - Rewrote all variable definitions to use pure makefile constructs
# V1
# - Initial (and extremely rudimentary) release

# #####################################
# Variables used by commands in recipes
# #####################################

# Don't modify this makefile directly! Create a file with the extension '.mk'
#  in the same directory as this file and it will be included automatically.
#
# To export all of the GIFs at the default suggested framerate, you may want
#  to use settings like these:
#   PROJNAME:= ${DIRNAME}-anim
#   INKSCAPEFLAGS:= ${INKSCAPEFLAGS} -y 1.0
#   TARGETS:= all-gif
# Find your animations in out/ after running the makefile.
#
# To export Telegram stickers for immediate upload by yourself, it's enough to
#  change the default target:
#   TARGETS:= small-opt
# Find your stickers in work/opt-small/ after running the makefile.
#
# The default settings are reasonable for packing artwork for distribution,
#  including Telegram stickers.
# Find your distribution zip-ball in out/ after running the makefile.

DIRNAME:=$(notdir ${CURDIR})
PROJNAME:=${DIRNAME}-stickers

SHELL:=/bin/mksh
INKSCAPE:=/usr/bin/inkscape -z
CONVERT:=/usr/bin/convert
PNGCRUSH:=/usr/bin/pngcrush -q
OPTIPNG:=/usr/bin/optipng -quiet
GIFSICLE:=/usr/bin/gifsicle
FFMPEG:=/usr/bin/ffmpeg
MKDIR:=/bin/mkdir -p
RM:=/bin/rm -rf
ZIP:=/usr/bin/zip -q
LN:=/bin/ln -sf
ECHO:=/bin/echo -e
REALPATH:=/usr/bin/realpath
READLINK:=/usr/bin/readlink

INKSCAPEFLAGS:= -C
GIFFLAGS:= -loop 0 -layers OptimizeTransparency +map
PNGCRUSHFLAGS:= -brute
OPTIPNGFLAGSS:= -o5
GIFSICLEFLAGS:= -O3

FFMPEG_QUIET:= -loglevel quiet -nostdin -y
FFMPEG_FILTERS:= -filter_complex "sws_flags=accurate_rnd+full_chroma_inp+lanczos;[0:v]scale=ceil((iw*min(1\,min(400/iw\,400/ih)))/2)*2:-2,format=pix_fmts=yuv420p" -preset veryslow -profile:v baseline -crf 18 -an

# Note: The GIF delay is 100/?; ex. a delay of 8 is 12.5 FPS.
#  Try to pick a similar GIF delay and video framerate.
GIF_FRAMEDELAY:= 8
FFMPEG_FRAMERATE:= 12
FFMPEG_PATTERN:= -start_number 1 -i work/large/frame%02d.png

TARGETS:= pack

# Everything before this line are variables a user may want to change.
-include *.mk

VECDIR:=vec/
WORKDIR:=work/
OUTDIR:=out/
OPTKEYWORD:=opt-
PACKDIR:=${PROJNAME}/
SMALLDIR:=${WORKDIR}small/
LARGEDIR:=${WORKDIR}large/
EXPSMALLDIR:=${WORKDIR}${OPTKEYWORD}small/
EXPLARGEDIR:=${WORKDIR}${OPTKEYWORD}large/
PACKSMALLDIR:=${PACKDIR}small/
PACKLARGEDIR:=${PACKDIR}large/

# ############################################
# Dynamically generated dependency information
# ############################################

# Detect SVG files in the project folder
FILES:=$(sort $(notdir $(wildcard ${VECDIR}*.svg)))

# Create target file names from the above information
SMALL:=$(patsubst %.svg,${SMALLDIR}%.png,${FILES})
LARGE:=$(patsubst %.svg,${LARGEDIR}%.png,${FILES})
EXPSMALL:=$(patsubst %.svg,${EXPSMALLDIR}%.png,${FILES})
EXPLARGE:=$(patsubst %.svg,${EXPLARGEDIR}%.png,${FILES})
PACKSMALL:=$(patsubst %.svg,${PACKSMALLDIR}%.png,${FILES})
PACKLARGE:=$(patsubst %.svg,${PACKLARGEDIR}%.png,${FILES})

# #######################################
# Special rules to change make's behavior
# #######################################

.SUFFIXES:
.PRECIOUS: %/
.PHONY: small large small-opt large-opt clean packclean distclean pack gif-tg gif-fa gif-opt gif-fa-opt gif all-gif gif-faava gif-faava-opt

# ############################
# End-user, "friendly" targets
# ############################

default: ${TARGETS}

large: ${LARGE}

large-opt: ${EXPLARGE}

small: ${SMALL}

small-opt: ${EXPSMALL}

pack: ${OUTDIR}${PROJNAME}.zip

all-gif: gif-opt gif-fa-opt gif-faava-opt gif-tg

gif: ${WORKDIR}${PROJNAME}.gif

gif-opt: ${OUTDIR}${PROJNAME}.gif

gif-fa: ${WORKDIR}${PROJNAME}-1280.gif

gif-fa-opt: ${OUTDIR}${PROJNAME}-1280.gif

gif-faava: ${WORKDIR}${PROJNAME}-100.gif

gif-faava-opt: ${OUTDIR}${PROJNAME}-100.gif

gif-tg: ${OUTDIR}${PROJNAME}.mp4

clean:
	@${ECHO} " RM\t${WORKDIR}"; ${RM} ${WORKDIR}

packclean:
	@${ECHO} " RM\t${PACKDIR}"; ${RM} ${PACKDIR}

distclean: clean packclean
	@${ECHO} " RM\t${OUTDIR}"; ${RM} ${OUTDIR}

# ###############################################
# Rules to build individual files and directories
# ###############################################

.SECONDEXPANSION:

define OPTIPNG_CMD =
${OPTIPNG} -force -clobber ${OPTIPNGFLAGS} $@ -out $<
endef

define PNGCRUSH_CMD =
${PNGCRUSH} ${PNGCRUSHFLAGS} $< $@
endef

define symlink_wrapper =
	@REALPATH=`${REALPATH} --relative-to=. $<`; \
	REALFILE=`${READLINK} $<`; \
	  if [ $$REALPATH != $< ]; then \
	    ${ECHO} " LN\t$@"; \
	    ${LN} $(if $(findstring .svg,$<),$${REALFILE%.svg}.png,$$REALFILE) $@; \
	  else \
	    ${ECHO} " ${1}\t$@"; \
	    ${2}; \
	  fi
endef

define gif_function =
${WORKDIR}%$(if ${1},-${1}).gif: $(shell if [[ "${1}" -le "512" ]]; then ${ECHO} "${SMALL}"; else ${ECHO} "${LARGE}"; fi) | $$(dir $$@)
	@${ECHO} " GIF\t$$@"; ${CONVERT} -delay ${GIF_FRAMEDELAY} ${GIFFLAGS} $$^ $(if ${1},-resize "${1}x${1}" )$$@
endef

%/:
	@${ECHO} " MKDIR\t$@"; ${MKDIR} $@

${LARGEDIR}%.png: ${VECDIR}%.svg | $$(dir $$@)
	$(call symlink_wrapper,INK,${INKSCAPE} ${INKSCAPEFLAGS} -e $@ $< >/dev/null)

${SMALLDIR}%.png: ${LARGEDIR}%.png | $$(dir $$@)
	$(call symlink_wrapper,CONV,${CONVERT} $< -resize "512x512" $@)

${WORKDIR}${OPTKEYWORD}%.png: ${WORKDIR}%.png | $$(dir $$@)
	$(call symlink_wrapper,OPT,${PNGCRUSH_CMD})

${OUTDIR}${PROJNAME}.zip ${PACKSMALLDIR} ${PACKLARGEDIR}: ${EXPSMALL} ${EXPLARGE} | $$(dir $$@) ${PACKDIR}
	@${ECHO} " LN\t${PACKSMALLDIR}"; ${LN} `${REALPATH} -m --relative-to=${PACKSMALLDIR}../ ${EXPSMALLDIR}` $(patsubst %/,%,${PACKSMALLDIR})
	@${ECHO} " LN\t${PACKLARGEDIR}"; ${LN} `${REALPATH} -m --relative-to=${PACKLARGEDIR}../ ${EXPLARGEDIR}` $(patsubst %/,%,${PACKLARGEDIR})
	@${ECHO} " ZIP\t$@"; ${ZIP} $@ ${PACKSMALL} ${PACKLARGE}

$(eval $(call gif_function))

$(eval $(call gif_function,1280))

$(eval $(call gif_function,100))

${OUTDIR}%.gif: ${WORKDIR}%.gif | $$(dir $$@)
	@${ECHO} " OPT\t$@"; ${GIFSICLE} ${GIFSICLEFLAGS} -o $@ $<

${OUTDIR}%.mp4: ${LARGE} | $$(dir $$@)
	@${ECHO} " VID\t$@"; ${FFMPEG} ${FFMPEG_QUIET} -r ${FFMPEG_FRAMERATE} ${FFMPEG_PROPERTIES} ${FFMPEG_PATTERN} ${FFMPEG_FILTERS} $@

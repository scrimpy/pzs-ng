/*
 * mp3tech.h - Headers for mp3tech.c
 * 
 * Copyright (C) 2000-2001  Cedric Tefft <cedric@earthling.net>
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 675
 * Mass Ave, Cambridge, MA 02139, USA.
 * 
**************************************************************************
 * 
 * 
 * This file is based in part on:
 * 
 * MP3Info 0.5 by Ricardo Cerqueira <rmc@rccn.net> MP3Stat 0.9 by Ed Sweetman
 * <safemode@voicenet.com> and Johannes Overmann <overmann@iname.com>
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <ctype.h>
#include <string.h>
#include "objects.h"

/*
 * MIN_CONSEC_GOOD_FRAMES defines how many consecutive valid MP3 frames we
 * need to see before we decide we are looking at a real MP3 file
 */
#define MIN_CONSEC_GOOD_FRAMES 4
#define FRAME_HEADER_SIZE 4
#define MIN_FRAME_SIZE 21
#define NUM_SAMPLES 4

typedef struct {
	unsigned int	sync;
	unsigned int	version;
	unsigned int	layer;
	unsigned int	crc;
	unsigned int	bitrate;
	unsigned int	freq;
	unsigned int	padding;
	unsigned int	extension;
	unsigned int	mode;
	unsigned int	mode_extension;
	unsigned int	copyright;
	unsigned int	original;
	unsigned int	emphasis;
}		mp3header;

typedef struct {
	char		title     [31];
	char		artist    [31];
	char		album     [31];
	char		year      [5];
	char		comment   [31];
	unsigned char	track[1];
	unsigned char	genre[1];
}		id3tag;

typedef struct {
	char		title     [31];
	char		artist    [31];
	char		album     [31];
	char		year      [5];
	char		comment   [31];
	unsigned char	track[1];
	unsigned char	genre[1];
	unsigned int	version[2];
	unsigned int	flags[1];
	long		size;
	long		ext_size;
	char		frame_id[5];
}		id3v2tag;


typedef struct {
	char           *filename;
	FILE           *file;
	off_t		datasize;
	int		header_isvalid;
	mp3header	header;
	int		id3_isvalid;
	id3tag		id3;
	id3v2tag	id3v2;
	int		vbr;
	float		vbr_average;
	int		seconds;
	int		frames;
	int		badframes;
}		mp3info;

int		get_header (FILE * file, mp3header * header);
int		frame_length(mp3header * header);
int		header_layer(mp3header * h);
int		header_bitrate(mp3header * h);
int		sameConstant(mp3header * h1, mp3header * h2);
void		get_mp3_info(char *f, struct audio *);
int		get_id3    (mp3info * mp3, struct audio *);
char           *unpad(char *string);
char           *unpadpre(char *string);
char           *getgenre(char *string);
int		header_frequency(mp3header * h);
char           *header_emphasis(mp3header * h);
char           *header_mode(mp3header * h);
int		get_first_header(mp3info * mp3, int startpos);
int		get_next_header(mp3info * mp3);
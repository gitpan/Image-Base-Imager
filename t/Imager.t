#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Imager.
#
# Image-Base-Imager is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Imager is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Imager.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
BEGIN {
  plan tests => 1513;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Imager;
MyTestHelpers::diag ("Imager VERSION ",Imager->VERSION);
MyTestHelpers::diag ("Imager write_types: ",join(',',Imager->write_types));

my $test_file_format;
{
  my @write_types = Imager->write_types;
  # Can rely on at least one writable type ?
  # if (! @write_types) {
  #   plan skip_all => 'due to strange no write_types at all';
  # }
  $test_file_format = $write_types[0];
  MyTestHelpers::diag ("test_file_format ", $test_file_format);
}

require Image::Base::Imager;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 4;
ok ($Image::Base::Imager::VERSION,
    $want_version,
    'VERSION variable');
ok (Image::Base::Imager->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { Image::Base::Imager->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::Imager->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");


#-----------------------------------------------------------------------------
# -file_format

{
  my @write_types = Imager->write_types;

  my $image = Image::Base::Imager->new;
  {
    my $format = $write_types[0];
    $image->set (-file_format => $format);
    ok ($image->get('-file_format'), $format,
        "set() -file_format to $format");
  }
  {
    $image->set (-file_format => undef);
    ok (! defined ($image->get('-file_format')),
        1,
        "set() -file_format to undef");
  }

  # -file_format is not checked on set()
  # {
  #   my $eval = eval {
  #     $image->set(-file_format => 'image-base-imager-test-no-such-format');
  #     1;
  #   };
  #   my $err = $@;
  #   ok ($eval, undef,
  #       'set() -file_format invalid eval');
  #   like ($err, '/Unrecognised -file_format/',
  #         'set() -file_format invalid error');
  # }
}


#------------------------------------------------------------------------------
# new() clone image, and resize

{
  my $i1 = Image::Base::Imager->new
    (-width => 11, -height => 22);
  my $i2 = $i1->new;
  $i2->set(-width => 33, -height => 44);

  ok ($i1->get('-width'), 11, 'clone original width');
  ok ($i1->get('-height'), 22, 'clone original height');
  ok ($i2->get('-width'), 33, 'clone new width');
  ok ($i2->get('-height'), 44, 'clone new height');
  ok ($i1->get('-imager') != $i2->get('-imager'),
      1,
      'cloned -imager object different');
}

#------------------------------------------------------------------------------
# xy

{
  my $image = Image::Base::Imager->new
    (-width => 20,
     -height => 10);
  $image->xy (2,2, 'black');
  ok ($image->xy (2,2), '#000000', 'xy() black');
  require Imager::Color;
  $image->xy (3,3, Imager::Color->new(red=>1,blue=>2,green=>3));
  ok ($image->xy (3,3), '#010203', 'xy() rgb');
}
{
  my $image = Image::Base::Imager->new
    (-width => 2, -height => 2);
  $image->set(-width => 20, -height => 20);

  $image->xy (10,10, 'white');
  ok ($image->xy (10,10), '#FFFFFF', 'xy() in resize');
}


#------------------------------------------------------------------------------
# load() errors

my $temp_filename = "tempfile.$test_file_format";
MyTestHelpers::diag ("Tempfile $temp_filename");
unlink $temp_filename;
ok (! -e $temp_filename,
    1,
    "removed any existing $temp_filename");
END {
  if (defined $temp_filename) {
    MyTestHelpers::diag ("Remove tempfile $temp_filename");
    unlink $temp_filename
      or MyTestHelpers::diag("Oops, cannot remove $temp_filename: $!");
  }
}

{
  my $eval_ok = 0;
  my $ret = eval {
    my $image = Image::Base::Imager->new (-file => $temp_filename);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # diag "new() err is \"",$err,"\"";
  ok ($eval_ok, 0, 'new() error for no file - doesn\'t reach end');
  ok (! defined $ret, 1, 'new() error for no file - return undef');
  ok ($err,
      '/^Cannot/',
      'new() error for no file - error string "Cannot"');
}
{
  my $eval_ok = 0;
  my $image = Image::Base::Imager->new;
  my $ret = eval {
    $image->load ($temp_filename);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # diag "load() err is \"",$err,"\"";
  ok ($eval_ok, 0, 'load() error for no file - doesn\'t reach end');
  ok (! defined $ret, 1, 'load() error for no file - return undef');
  ok ($err,
      '/^Cannot/',
      'load() error for no file - error string "Cannot"');
}

#-----------------------------------------------------------------------------
# save() errors

{
  my $eval_ok = 0;
  my $nosuchdir = "no/such/directory/foo.$test_file_format";
  my $image = Image::Base::Imager->new (-width => 1,
                                        -height => 1);
  my $ret = eval {
    $image->save ($nosuchdir);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # diag "save() err is \"",$err,"\"";
  ok ($eval_ok, 0, 'save() error for no dir - doesn\'t reach end');
  ok (! defined $ret, 1, 'save() error for no dir - return undef');
  ok ($err, '/^Cannot/', 'save() error for no dir - error string "Cannot"');
}
{
  my $eval_ok = 0;
  my $nosuchext = 'tempfile.unrecognisedextension';
  my $image = Image::Base::Imager->new (-width => 1,
                                        -height => 1);
  my $ret = eval {
    $image->save ($nosuchext);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # diag "save() err is \"",$err,"\"";
  ok ($eval_ok, 0, 'save() error for unknown ext - doesn\'t reach end');
  ok (! defined $ret, 1, 'save() error for unknown ext - return undef');
  ok ($err, '/^Cannot/', 'save() error for no dir - error string "Cannot"');
}


#-----------------------------------------------------------------------------
# save() / load()

{
  require Imager;
  my $imager_obj = Imager->new (xsize => 20, ysize => 10);
  ok ($imager_obj->getwidth, 20);
  ok ($imager_obj->getheight, 10);
  my $image = Image::Base::Imager->new
    (-imager => $imager_obj);
  $image->save ($temp_filename);
  ok (-e $temp_filename,
      1,
      "save() to $temp_filename, -e exists");
  ok (-s $temp_filename > 0,
      1,
      "save() to $temp_filename, -s non-empty");
}
{
  my $image = Image::Base::Imager->new (-file => $temp_filename);
  ok ($image->get('-file_format'),
      $test_file_format,
      'load() with new(-file)');
}
{
  my $image = Image::Base::Imager->new;
  $image->load ($temp_filename);
  ok ($image->get('-file_format'),
      $test_file_format,
      'load() method');
}

#------------------------------------------------------------------------------
# save -file_format

{
  my $imager_obj = Imager->new (xsize => 10, ysize => 10);
  my $image = Image::Base::Imager->new
    (-imager      => $imager_obj,
     -file_format => $test_file_format);
  $image->save ($temp_filename);
  ok (-e $temp_filename,
      1,
      'save() with -file_format exists');
  ok (-s $temp_filename > 0,
      1,
      'save() with -file_format not empty');

  # system ("ls -l $temp_filename");
  # system ("file $temp_filename");
}
{
  my $image = Image::Base::Imager->new (-file => $temp_filename);
  ok ($image->get('-file_format'),
      $test_file_format,
      'save() -file_format load back format');
}

#------------------------------------------------------------------------------
# save_fh()

{
  my $image = Image::Base::Imager->new (-width => 1,
                                        -height => 1,
                                        -file_format => $test_file_format);
  unlink $temp_filename;
  open OUT, "> $temp_filename" or die;
  $image->save_fh (\*OUT);
  close OUT or die;
  ok (-s $temp_filename > 0,
      1,
      'save_fh() not empty');
}

#------------------------------------------------------------------------------
# load_fh()

{
  my $image = Image::Base::Imager->new;
  open IN, "< $temp_filename" or die;
  $image->load_fh (\*IN);
  close IN or die;
  ok ($image->get('-file_format'),
      $test_file_format,
      'load_fh() -file_format');
}

#------------------------------------------------------------------------------
# CUR -hotx, -hoty

my $have_cur = eval { Imager->VERSION(0.52); 1 };
if (! $have_cur) {
  MyTestHelpers::diag ('CUR new in Imager 0.52, have only', Imager->VERSION);
}

{
  my $imager_obj = Imager->new (xsize => 20,
                                ysize => 10,
                                -file_format => 'CUR');
  $imager_obj->settag (name => 'cur_hotspotx', value => 5);
  $imager_obj->settag (name => 'cur_hotspoty', value => 6);

  my $image = Image::Base::Imager->new
    (-imager => $imager_obj);
  ok ($image->get ('-hotx'), 5, 'get(-hotx)');
  ok ($image->get ('-hoty'), 6, 'get(-hoty)');

  $image->set (-hotx => 7, -hoty => 8);
  ok ($image->get ('-hotx'), 7, 'get(-hotx)');
  ok ($image->get ('-hoty'), 8, 'get(-hoty)');
}

{
  my $image = Image::Base::Imager->new
    (-width       => 20,
     -height      => 10,
     -hotx        => 3,
     -hoty        => 4,
     -file_format => 'CUR');
  ok ($image->get ('-hotx'), 3, 'get(-hotx)');
  ok ($image->get ('-hoty'), 4, 'get(-hoty)');

  $image->save($temp_filename);
  open IN, "< $temp_filename" or die;
  my $content_one = do { local $/; <IN> }; # slurp
  close IN or die;

  $image->set (-hotx => 7, -hoty => 8);
  $image->save($temp_filename);
  open IN, "< $temp_filename" or die;
  my $content_two = do { local $/; <IN> }; # slurp
  close IN or die;

  ok ($content_one ne $content_two,
      1,
      'CUR hotx/hoty differ');
}

#------------------------------------------------------------------------------
# check_image

{
  my $image = Image::Base::Imager->new
    (-width  => 20,
     -height => 10);
  ok ($image->get('-width'), 20);
  ok ($image->get('-height'), 10);

  $image->xy (0,0, 'red');
  ok ($image->xy(0,0), '#FF0000');

  require MyTestImageBase;
  MyTestImageBase::check_image ($image);
}

exit 0;

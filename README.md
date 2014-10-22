Sayori
======

Sayori is XHTML rendering engine for OS X and iOS


How to add Sayori to your project
---------------------------------

Copy Sayori into same directory as your existing project (e.g. as a git submodule)
Drag Sayori's .xcodeproj file into your project.

Open the Build Phases panel in your project settings, add libsayori.a (iOS) as a
target dependency. Then link to the following libraries

- libsayori.a (iOS)
- libxml2.a
- libiconv.a
- Sayori/source/libcss/lib/

Open the Build Settings panel and add the following lines to your "Header Search Paths":

- $(SDKROOT)/usr/include/libxml2
- $(SRCROOT)/Sayori/source/libcss/include

Add the following lines to your "Library Search Paths"

- $(SRCROOT)/Sayori/source/libcss/lib/$(PLATFORM_NAME)

Finally, in every file where you want to use Sayori's code, add the following statement at the top:

	# include <Sayori/Sayori.h>

That's it.


PHOTO & SLIDE CLASSIFIER
VERSION 1

OFFLINE TAXONOMY CLASSIFICATION APPLICATION


FOLDER STRUCTURE
================

PhotoClassifier/
    PhotoClassifier.html
    README.txt

    taxonomy/
        subjects.txt
        keywords.txt
        aircraft.txt


FIRST USE
=========

1. Open PhotoClassifier.html in a web browser.

2. Go to TAXONOMY.

3. Select:
       subjects.txt
       keywords.txt
       aircraft.txt

4. Click LOAD TAXONOMY.

The taxonomy is then stored locally in the browser.

The application does not send the taxonomy or classification
descriptions to an internet server.


CLASSIFYING A COLLECTION
========================

1. Go to CLASSIFY.

2. Describe the group of photographs/slides.

Example:

    Old photographs of mechanics working on an airplane
    engine inside a hangar.

3. Click FIND CATEGORIES.

4. Review the suggestions.

5. Check the categories that actually apply.

6. Click GENERATE FOLDER LABEL.

7. Copy the suggested label or edit it.


UPDATING THE TAXONOMY
=====================

The three TXT files are the source of truth.

When the organization's Excel taxonomy changes:

1. Update subjects.txt.
2. Update keywords.txt.
3. Update aircraft.txt.

Then open the application and go to TAXONOMY.

Select the updated files and click LOAD TAXONOMY.

The application rebuilds its local taxonomy from those files.


IMPORTANT
=========

The official taxonomy names should remain in the TXT files.

Do not rename taxonomy terms merely to make the classifier
sound better.

The classifier is an assistant. The archivist makes the final
classification decision.


OFFLINE OPERATION
=================

After the taxonomy has been loaded, classification works
without an internet connection.

The browser stores the parsed taxonomy locally.

Classification history is also stored locally.


MOVING TO ANOTHER DEVICE
========================

Copy:

    PhotoClassifier.html
    taxonomy/
        subjects.txt
        keywords.txt
        aircraft.txt

to the other computer, phone, or tablet.

On the new device, open the HTML application and load the
three taxonomy files once.

The application can then be used offline.


BACKUP
======

Always retain backup copies of:

    subjects.txt
    keywords.txt
    aircraft.txt

These files represent the organization's classification
taxonomy used by the application.


FUTURE DEVELOPMENT
==================

Possible future versions can add:

- Better semantic matching
- Better synonym handling
- More sophisticated ranking
- Taxonomy validation
- Taxonomy change reports
- Duplicate detection
- Test cases
- Photo upload and image recognition
- PWA installation
- Automatic loading of bundled taxonomy files
- Export of classification records
- QR/barcode support
- Batch classification
var issnValidator = function(text) {
  var issnMatch = /^[0-9]{4}-[0-9X]{4}$/;
  return {
    valid: issnMatch.test(text),
    msg: 'Must be like 1234-5678 or 1234-567X'
  };
}

var yearValidator = function(text) {
  var yearMatch = /^[0-9]{4}$/;
  return {
    valid: yearMatch.test(text),
    msg: 'Must have four digits, such as 1999'
  };
}

var ARTICLE_FIELDS = [
  {
    label: 'First author',
    id: 'first-author',
    requiredSet: 1,
    tooltip: 'Name of the primary or first author'
  },
  {
    label: 'Page number',
    id: 'page-number',
    requiredSet: 1,
    tooltip: 'First page the article appears on'
  },
  {
    label: 'Article number',
    id: 'article-number',
    requiredSet: 1
  },
  {
    label: 'Journal title',
    id: 'journal-title',
    help: '<a href="http://www.crossref.org/titleList/" target="_blank">'
          + '<i class="icon-external-link"></i>&nbsp;Browse title list'
           + '</a>'
  },
  {
    label: 'ISSN',
    id: 'issn',
    validate: issnValidator,
    tooltip: 'Electronic or print ISSN of journal'
  },
  {
    label: 'Article title',
    id: 'article-title',
    tooltip: 'Fuzzy match article title'
  },
  {
    label: 'Volume',
    id: 'volume',
    tooltip: 'Journal volume'
  },
  {
    label: 'Issue',
    id: 'issue',
    tooltip: 'Journal issue'
  },
  {
    label: 'Year',
    id: 'year',
    validate: yearValidator,
    tooltip: 'Year of publication'
  }
];

var CHAPTER_FIELDS = [
  {
    label: 'First author',
    id: 'first-author',
    requiredSet: 1
  },
  {
    label: 'Page number',
    id: 'page-number',
    requiredSet: 1
  },
  {
    label: 'Book title',
    id: 'book-title',
    requiredSet: 2
  },
  {
    label: 'ISBN',
    id: 'isbn',
    requiredSet: 2
  },
  {
    label: 'Chapter title',
    id: 'chapter-title'
  },
  {
    label: 'Chapter number',
    id: 'chapter-number'
  },
  {
    label: 'Volume number',
    id: 'volume-number'
  },
  {
    label: 'Edition',
    id: 'edition'
  },
  {
    label: 'Year',
    id: 'year',
    validate: yearValidator
  },
  {
    label: 'Book series title',
    id: 'book-series-title'
  },
  {
    label: 'ISSN',
    id: 'issn',
    validate: issnValidator
  }
];

var BOOK_FIELDS = [
  {
    label: 'Author',
    id: 'author'
  },
  {
    label: 'Book title',
    id: 'book-title',
    requiredSet: 1
  },
  {
    label: 'ISBN',
    id: 'isbn'
  },
  {
    label: 'Volume',
    id: 'volume'
  },
  {
    label: 'Edition',
    id: 'edition'
  },
  {
    label: 'Year',
    id: 'year',
    validate: yearValidator
  },
  {
    label: 'ISSN',
    id: 'issn',
    validate: issnValidator
  }
];

var CONF_PAPER_FIELDS = [
  {
    label: 'First author',
    id: 'first-author',
    requiredSet: 1
  },
  {
    label: 'First page',
    id: 'first-page',
    requiredSet: 1
  },
  {
    label: 'Proceedings title',
    id: 'proceedings-title',
    requiredSet: 2
  },
  {
    label: 'ISBN',
    id: 'isbn',
    requiredSet: 2
  },
  {
    label: 'ISSN',
    id: 'issn',
    requiredSet: 2,
    validate: issnValidator
  },
  {
    label: 'Conference paper title',
    id: 'conference-paper-title',
  },
  {
    label: 'Institution',
    id: 'institution'
  },
  {
    label: 'Year',
    id: 'year',
    validate: yearValidator
  }
];

var OTHER_FIELDS = [
  {
    label: 'Title (item)',
    id: 'item-title',
    requiredSet: 1
  },
  {
    label: 'Title (volume)',
    id: 'volume-title',
    requiredSet: 1
  },
  {
    label: 'ISBN',
    id: 'isbn',
    requiredSet: 1
  },
  {
    label: 'First author',
    id: 'first-author'
  },
  {
    label: 'Institution',
    id: 'institution'
  },
  {
    label: 'Edition',
    id: 'edition'
  },
  {
    label: 'ISSN',
    id: 'issn',
    validate: issnValidator
  }
];

var FIELD_KIND_LOOKUP = {
  'article': ARTICLE_FIELDS,
  'conference-paper': CONF_PAPER_FIELDS,
  'chapter': CHAPTER_FIELDS,
  'book': BOOK_FIELDS,
  'other': OTHER_FIELDS
};

var FIELD_VALUES = {};

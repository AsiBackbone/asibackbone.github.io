(function () {
  'use strict'

  var sources = [
    { id: 'learning', label: 'Learning', base: 'https://asibackbone.github.io/Learning/', index: 'https://asibackbone.github.io/Learning/index.json' },
    { id: 'framework', label: 'Framework', base: 'https://asibackbone.github.io/AsiBackbone/', index: 'https://asibackbone.github.io/AsiBackbone/index.json' },
    { id: 'template', label: 'Template', base: 'https://asibackbone.github.io/NetCoreApplicationTemplate/', index: 'https://asibackbone.github.io/NetCoreApplicationTemplate/index.json' },
    { id: 'reference', label: 'Reference', base: 'https://asibackbone.github.io/ReferenceApplication/', index: 'https://asibackbone.github.io/ReferenceApplication/index.json' }
  ]

  var form = document.getElementById('organization-search')
  var queryInput = document.getElementById('search-query')
  var siteFilter = document.getElementById('site-filter')
  var output = document.getElementById('search-output')
  var status = document.getElementById('search-status')
  var resultsList = document.getElementById('search-results')
  var indexPromise = null
  var unavailableSites = []
  var currentQuery = ''
  var allResults = []

  function normalize(value) {
    return String(value || '').toLocaleLowerCase().replace(/[^\p{L}\p{N}._-]+/gu, ' ').trim()
  }

  function tokenize(value) {
    return normalize(value).split(/\s+/).filter(function (token) { return token.length > 1 })
  }

  function loadIndexes() {
    if (indexPromise) {
      return indexPromise
    }

    status.textContent = 'Loading documentation indexes…'
    indexPromise = Promise.allSettled(sources.map(function (source) {
      return fetch(source.index, { credentials: 'same-origin' })
        .then(function (response) {
          if (!response.ok) {
            throw new Error(source.label + ' returned HTTP ' + response.status)
          }
          return response.json()
        })
        .then(function (index) {
          return Object.keys(index).map(function (key) {
            var entry = index[key]
            return {
              site: source.id,
              siteLabel: source.label,
              href: new URL(entry.href || key, source.base).href,
              title: entry.title || key,
              summary: entry.summary || '',
              path: entry.href || key
            }
          })
        })
    })).then(function (settled) {
      var entries = []
      unavailableSites = []

      settled.forEach(function (result, index) {
        if (result.status === 'fulfilled') {
          entries = entries.concat(result.value)
        } else {
          unavailableSites.push(sources[index].label)
        }
      })

      return entries
    })

    return indexPromise
  }

  function scoreEntry(entry, terms, normalizedQuery) {
    var title = normalize(entry.title)
    var summary = normalize(entry.summary)
    var path = normalize(entry.path)
    var combined = title + ' ' + summary + ' ' + path

    if (!terms.every(function (term) { return combined.indexOf(term) >= 0 })) {
      return 0
    }

    var score = 1
    if (title === normalizedQuery) score += 100
    if (title.indexOf(normalizedQuery) === 0) score += 45
    if (title.indexOf(normalizedQuery) >= 0) score += 30
    if (path.indexOf(normalizedQuery) >= 0) score += 12

    terms.forEach(function (term) {
      if (title.split(' ').indexOf(term) >= 0) score += 15
      else if (title.indexOf(term) >= 0) score += 8
      if (path.indexOf(term) >= 0) score += 4
      if (summary.indexOf(term) >= 0) score += 2
    })

    return score
  }

  function renderResults() {
    var selectedSite = siteFilter.value
    var visible = allResults.filter(function (result) {
      return selectedSite === 'all' || result.entry.site === selectedSite
    }).slice(0, 100)

    resultsList.replaceChildren()

    visible.forEach(function (result) {
      var item = document.createElement('li')
      item.className = 'result'

      var heading = document.createElement('h3')
      var link = document.createElement('a')
      link.href = result.entry.href
      link.textContent = result.entry.title
      heading.appendChild(link)

      var meta = document.createElement('div')
      meta.className = 'result-meta'
      var badge = document.createElement('span')
      badge.className = 'site-badge'
      badge.textContent = result.entry.siteLabel
      var path = document.createElement('span')
      path.className = 'result-path'
      path.textContent = result.entry.path
      meta.append(badge, path)

      item.append(heading, meta)
      if (result.entry.summary) {
        var summary = document.createElement('p')
        summary.textContent = result.entry.summary.length > 320
          ? result.entry.summary.slice(0, 317).trimEnd() + '…'
          : result.entry.summary
        item.appendChild(summary)
      }

      resultsList.appendChild(item)
    })

    var availabilityNote = unavailableSites.length
      ? ' Indexes unavailable: ' + unavailableSites.join(', ') + '.'
      : ''

    if (!visible.length) {
      status.textContent = 'No results found for “' + currentQuery + '”' + (selectedSite === 'all' ? '.' : ' in ' + siteFilter.options[siteFilter.selectedIndex].text + '.')
    } else {
      var qualifier = selectedSite === 'all' ? '' : ' in ' + siteFilter.options[siteFilter.selectedIndex].text
      var capped = allResults.length > visible.length && selectedSite === 'all' ? ' Showing the first 100.' : ''
      status.textContent = visible.length + (visible.length === 1 ? ' result' : ' results') + ' for “' + currentQuery + '”' + qualifier + '.' + capped
    }

    status.textContent += availabilityNote
  }

  function search(query) {
    currentQuery = query.trim()
    output.hidden = false
    resultsList.replaceChildren()

    var terms = tokenize(currentQuery)
    if (!terms.length) {
      allResults = []
      status.textContent = 'Enter at least one word with two or more characters.'
      return Promise.resolve()
    }

    var normalizedQuery = normalize(currentQuery)
    status.textContent = 'Searching all documentation…'

    return loadIndexes().then(function (entries) {
      allResults = entries.map(function (entry) {
        return { entry: entry, score: scoreEntry(entry, terms, normalizedQuery) }
      }).filter(function (result) {
        return result.score > 0
      }).sort(function (left, right) {
        return right.score - left.score || left.entry.title.localeCompare(right.entry.title)
      })

      renderResults()
    }).catch(function () {
      allResults = []
      status.textContent = 'Search indexes could not be loaded. Please try again shortly.'
    })
  }

  form.addEventListener('submit', function (event) {
    event.preventDefault()
    var query = queryInput.value.trim()
    var url = new URL(window.location.href)
    if (query) url.searchParams.set('q', query)
    else url.searchParams.delete('q')
    window.history.replaceState(null, '', url)
    search(query)
  })

  siteFilter.addEventListener('change', renderResults)

  var initialQuery = new URLSearchParams(window.location.search).get('q') || ''
  if (initialQuery) {
    queryInput.value = initialQuery
    search(initialQuery)
  }
})()

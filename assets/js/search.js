let index = [];

async function loadIndex() {
  const res = await fetch('/search.json');
  index = await res.json();
}

function search(query) {
  if (!query.trim()) return [];
  const terms = query.toLowerCase().split(/\s+/);

  return index
    .map(entry => {
      const haystack = `${entry.title} ${entry.content}`.toLowerCase();
      let score = 0;
      for (const term of terms) {
        if (entry.title.toLowerCase().includes(term)) score += 3;
        if (haystack.includes(term)) score += 1;
      }
      return { entry, score };
    })
    .filter(r => r.score > 0)
    .sort((a, b) => b.score - a.score)
    .map(r => r.entry);
}

function render(results, query) {
  const list = document.getElementById('search-results');
  const status = document.getElementById('search-status');
  list.innerHTML = '';

  status.textContent = query
    ? `${results.length} resultado(s) para “${query}”`
    : '';

  for (const item of results) {
    const li = document.createElement('li');
    li.innerHTML = `<a href="${item.url}">${item.title}</a><p>${item.excerpt}</p>`;
    list.appendChild(li);
  }
}

document.addEventListener('DOMContentLoaded', async () => {
  await loadIndex();
  const input = document.getElementById('search-input');
  input.addEventListener('input', (e) => {
    render(search(e.target.value), e.target.value);
  });
});

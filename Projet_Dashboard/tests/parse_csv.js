// Substitut de Utilities.parseCsv(text, delimiter) : guillemets, "" echappes, retours a la ligne entre guillemets.
module.exports = (text, sep = ',') => {
  const rows = [[]];
  let cell = '', quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { cell += '"'; i++; }
      else if (c === '"') quoted = false;
      else cell += c;
    } else if (c === '"') quoted = true;
    else if (c === sep) { rows[rows.length - 1].push(cell); cell = ''; }
    else if (c === '\n') { rows[rows.length - 1].push(cell.replace(/\r$/, '')); rows.push([]); cell = ''; }
    else cell += c;
  }
  rows[rows.length - 1].push(cell);
  return rows;
};

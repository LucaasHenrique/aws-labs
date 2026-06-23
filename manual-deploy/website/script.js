const yearElement = document.getElementById('year');
const statusButton = document.getElementById('statusButton');
const statusText = document.getElementById('statusText');

yearElement.textContent = new Date().getFullYear();

const messages = [
  'Pronto para deploy',
  'Container preparado para teste',
  'Website servindo via Nginx',
];

let messageIndex = 0;

statusButton.addEventListener('click', () => {
  messageIndex = (messageIndex + 1) % messages.length;
  statusText.textContent = messages[messageIndex];
});
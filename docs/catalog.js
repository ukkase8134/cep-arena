'use strict';
const search=document.getElementById('game-search');
const buttons=[...document.querySelectorAll('[data-category][type="button"]')];
const cards=[...document.querySelectorAll('article.game-card')];
let category='Tümü';
function filterGames(){
  const term=search.value.trim().toLocaleLowerCase('tr');
  let count=0;
  for(const card of cards){
    const shown=(category==='Tümü'||card.dataset.category===category)&&
      card.dataset.name.toLocaleLowerCase('tr').includes(term);
    card.hidden=!shown;if(shown)count++;
  }
  document.getElementById('catalog-count').textContent=count+' oyun';
  for(const button of buttons)button.setAttribute('aria-pressed',String(button.dataset.category===category));
}
search.addEventListener('input',filterGames);
for(const button of buttons)button.addEventListener('click',()=>{category=button.dataset.category;filterGames();});

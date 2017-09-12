import { Main } from './Main.elm';
import { initLocalStoragePort } from './localStoragePort';
const app = Main.embed(document.getElementById('oration'));

initLocalStoragePort(app);


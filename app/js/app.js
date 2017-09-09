import Elm from './main';
import { initLocalStoragePort } from './localStoragePort';
const elmDiv = document.getElementById('oration');
if (elmDiv) {
    const app = Elm.Main.embed(elmDiv);
    initLocalStoragePort(app);
}

module Main exposing (..)

import Html exposing (..)
import Models exposing (initialModel)
import Storage exposing (loadUserState)
import Update exposing (update, subscriptions)
import View exposing (view)

main =
    Html.program { init = (initialModel, loadUserState), view = view, update = update, subscriptions = subscriptions }


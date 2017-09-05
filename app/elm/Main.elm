module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import AutoExpand exposing (withPlaceholder)
import Identicon exposing (identicon)
import Markdown


main =
    Html.beginnerProgram { model = model, view = view, update = update }



-- MODEL


type alias Model =
    { comment : String
    , name : String
    , email : String
    , url : String
    , preview : Bool
    , autoexpand : AutoExpand.State
    , inputText : String
    }


model : Model
model =
    Model "" "" "" "" False (AutoExpand.initState config) ""



-- UPDATE


type Msg
    = Comment String
    | Name String
    | Email String
    | Url String
    | Preview
    | AutoExpandInput { textValue : String, state : AutoExpand.State }


update : Msg -> Model -> Model
update msg model =
    case msg of
        Comment comment ->
            { model | comment = comment }

        Name name ->
            { model | name = name }

        Email email ->
            { model | email = email }

        Url url ->
            { model | url = url }

        Preview ->
            { model | preview = not model.preview }

        AutoExpandInput { state, textValue } ->
            { model
                | autoexpand = state
                , inputText = textValue
            }



-- VIEW


view : Model -> Html Msg
view model =
    let
        identity =
            String.concat [ model.name, ", ", model.email, ", ", model.url ]

        markdown =
            markdownContent model.comment model.preview
    in
    div [ id "oration-post" ]
        [ Html.form [ action "/", method "post", id "oration-form" ]
            [ AutoExpand.view config model.autoexpand model.inputText
            , textarea [ name "comment", placeholder "Write a comment here (min 3 characters).", minlength 3, cols 55, rows 4, onInput Comment ] []
            , div [ id "oration-auth" ]
                [ span [ id "oration-identicon" ] [ identicon "25px" identity ]
                , input [ type_ "text", name "name", placeholder "Name (optional)", autocomplete True, onInput Name ] []
                , input [ type_ "email", name "email", placeholder "Email (optional)", autocomplete True, onInput Email ] []
                , input [ type_ "url", name "url", placeholder "Website (optional)", onInput Url ] []
                , input [ type_ "checkbox", id "oration-preview-check", name "preview", onClick Preview ] []
                , label [ for "oration-preview-check" ] [ text "Preview" ]
                , input [ type_ "submit", class "oration-submit", value "Comment" ] []
                ]
            , viewValidation model
            ]
        , div [ id "comment-preview" ] <|
            Markdown.toHtml Nothing markdown
        ]


viewValidation : Model -> Html msg
viewValidation model =
    let
        ( color, message ) =
            if String.length model.comment > 3 then
                ( "green", "OK" )
            else
                ( "red", "Comment it too short." )
    in
    div [ class color ] [ text message ]


markdownContent : String -> Bool -> String
markdownContent content preview =
    if preview then
        content
    else
        ""

{-| Configuration for AutoExpand. -}
config : AutoExpand.Config Msg
config =
    AutoExpand.config
        { onInput = AutoExpandInput
        , padding = 10
        , lineHeight = 20
        , minRows = 4
        , maxRows = 20
        }
        |> withPlaceholder "Write a comment here (min 3 characters)."

# Gather data from multiple sports into one dataset
# Games from 2010 through 2020
library(conflicted)
library(tidyverse)
library(lubridate)
library(glue)
filter <- dplyr::filter

nhl <- read_csv(
  "C:/Users/abreza/Downloads/archive.zip",
  col_types = cols_only(away_goals = col_integer(),
                        home_goals = col_integer())
) %>%
  mutate(sport = "hockey") %>% 
  select(home_score = home_goals, away_score = away_goals, sport)

nba <- read_csv("C:/Users/abreza/Downloads/archive (1).zip") %>%
  filter(year(GAME_DATE_EST) > 2009) %>%
  mutate(sport = "basketball") %>%
  select(home_score = PTS_home,
         away_score = PTS_away,
         sport)

get_baseball <- function(path) {
  read_csv(
    "GL2010.TXT",
    col_names = FALSE,
    col_types = cols_only(X10 = col_integer(),
                          X11 = col_integer())
  ) %>%
    set_names(c("away_score", "home_score")) %>%
    select(home_score, away_score) %>% 
    mutate(sport = "baseball")
}

mlb <- map_dfr(list.files(pattern = "GL"), get_baseball)

get_football <- function(year) {
  regular <-
    read_csv(
      glue(
        "https://raw.githubusercontent.com/ryurko/nflscrapR-data/master/games_data/regular_season/reg_games_{year}.csv"
      ),
      col_types = cols_only(home_score = col_integer(), away_score = col_integer())
    )
  playoffs <-
    read_csv(
      glue(
        "https://raw.githubusercontent.com/ryurko/nflscrapR-data/master/games_data/post_season/post_games_{year}.csv"
      ),
      col_types = cols_only(home_score = col_integer(), away_score = col_integer())
    )
  rbind(regular, playoffs) %>% 
    na.omit() %>% 
    mutate(sport = "football")
}

nfl <- map_dfr(2009:2019, get_football)

all.equal(names(nfl), names(nba), names(mlb))

sport <- rbind(nfl, nba, mlb) %>% 
  na.omit() %>% 
  add_column(cv = sample(x = c(rep("train", 4), "test"), size = nrow(.), replace = TRUE))

write_csv(sport, "sport.csv")

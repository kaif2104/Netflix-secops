import Box from "@mui/material/Box";
import Alert from "@mui/material/Alert";
import AlertTitle from "@mui/material/AlertTitle";
import CircularProgress from "@mui/material/CircularProgress";
import Typography from "@mui/material/Typography";
import Stack from "@mui/material/Stack";
import { COMMON_TITLES } from "src/constant";
import HeroSection from "src/components/HeroSection";
import { genreSliceEndpoints, useGetGenresQuery } from "src/store/slices/genre";
import { MEDIA_TYPE } from "src/types/Common";
import { CustomGenre, Genre } from "src/types/Genre";
import SliderRowForGenre from "src/components/VideoSlider";
import store from "src/store";

export async function loader() {
  await store.dispatch(
    genreSliceEndpoints.getGenres.initiate(MEDIA_TYPE.Movie)
  );
  return null;
}
export function Component() {
  const { data: genres, isSuccess, isLoading, isError, error } = useGetGenresQuery(MEDIA_TYPE.Movie);

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 15 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (isError) {
    return (
      <Box sx={{ p: 4, maxWidth: 700, mx: "auto", mt: 12 }}>
        <Alert severity="error">
          <AlertTitle sx={{ fontWeight: "bold" }}>Failed to load movies from TMDB API</AlertTitle>
          <Typography variant="body2" sx={{ mb: 1, wordBreak: "break-all" }}>
            <strong>Error details:</strong> {JSON.stringify(error)}
          </Typography>
          <Typography variant="body2" component="div">
            <strong>Check the following:</strong>
            <ul>
              <li>
                <strong>ISP / DNS Block (very common in India):</strong> Indian ISPs (Jio, Airtel, etc.) block TMDB. Fix: In Chrome, go to <em>Settings &gt; Privacy &amp; security &gt; Security &gt; Use secure DNS &gt; Choose Cloudflare (1.1.1.1) or Google (8.8.8.8)</em>, or turn on a VPN.
              </li>
              <li>
                <strong>Invalid or Inactive TMDB API Key:</strong> Ensure your <code>VITE_APP_TMDB_V3_API_KEY</code> in <code>.env</code> is a valid API key from <a href="https://www.themoviedb.org/settings/api" target="_blank" rel="noreferrer" style={{ color: "inherit" }}>themoviedb.org</a>.
              </li>
            </ul>
          </Typography>
        </Alert>
      </Box>
    );
  }

  if (isSuccess && genres && genres.length > 0) {
    return (
      <Stack spacing={2}>
        <HeroSection mediaType={MEDIA_TYPE.Movie} />
        {[...COMMON_TITLES, ...genres].map((genre: Genre | CustomGenre) => (
          <SliderRowForGenre
            key={genre.id || genre.name}
            genre={genre}
            mediaType={MEDIA_TYPE.Movie}
          />
        ))}
      </Stack>
    );
  }
  return null;
}

Component.displayName = "HomePage";

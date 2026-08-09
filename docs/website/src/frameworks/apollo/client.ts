import { ApolloClient, ApolloLink, InMemoryCache, Observable, type FetchResult } from "@apollo/client";
import { getOperationName } from "@apollo/client/utilities";
import { getLoreStories, getLoreStoryById, getOutposts, getRaidLanes } from "./data";

/**
 * There is no live GraphQL server for this docs site (see src/graphql's
 * "MFP8+" note — content graph is scaffolded ahead of a real backend). This
 * link resolves `schema.graphql`'s actual Query fields against this repo's
 * real data (src/stories/ lore, the coastal outpost/raid-lane layout in
 * ./data.ts) instead of hitting the network — the same "real data, no live
 * server" bar src/graphql/schema.graphql's own header note sets, and the
 * same reuse ethic the Aurelia island applies to src/simulations/.
 */
const localSchemaLink = new ApolloLink((operation) => {
  return new Observable((observer) => {
    const name = getOperationName(operation.query);
    let data: FetchResult["data"];

    switch (name) {
      case "Outposts":
        data = { outposts: getOutposts() };
        break;
      case "RaidLanes":
        data = { raidLanes: getRaidLanes() };
        break;
      case "LoreStories":
        data = { loreStories: getLoreStories() };
        break;
      case "LoreStory":
        data = { loreStory: getLoreStoryById(operation.variables.id as string) };
        break;
      default:
        observer.error(new Error(`Apollo island: no local resolver for operation "${name}"`));
        return;
    }

    // Mirror real network latency so loading states are exercised too.
    const timer = setTimeout(() => {
      observer.next({ data });
      observer.complete();
    }, 120);

    return () => clearTimeout(timer);
  });
});

export const apolloClient = new ApolloClient({
  link: localSchemaLink,
  cache: new InMemoryCache(),
});

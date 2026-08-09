import { gql } from "@apollo/client";

/** Field shapes mirror src/graphql/schema.graphql's Query type exactly. */

export const OUTPOSTS_QUERY = gql`
  query Outposts {
    outposts {
      id
      kind
      label
      x
      y
    }
  }
`;

export const RAID_LANES_QUERY = gql`
  query RaidLanes {
    raidLanes {
      id
      approach
      label
    }
  }
`;

export const LORE_STORIES_QUERY = gql`
  query LoreStories {
    loreStories {
      id
      title
      era
      summary
      tags
      docPath
    }
  }
`;

export const LORE_STORY_QUERY = gql`
  query LoreStory($id: ID!) {
    loreStory(id: $id) {
      id
      title
      era
      summary
      tags
      docPath
    }
  }
`;

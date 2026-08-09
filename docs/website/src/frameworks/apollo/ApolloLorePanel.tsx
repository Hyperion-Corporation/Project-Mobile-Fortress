import { ApolloProvider, useQuery } from "@apollo/client";
import { apolloClient } from "./client";
import { LORE_STORIES_QUERY, OUTPOSTS_QUERY, RAID_LANES_QUERY } from "./queries";
import type { LoreStory, OutpostNode, RaidLane } from "../../interfaces/types";
import "./ApolloLorePanel.css";

function LoreStoriesGrid() {
  const { data, loading, error } = useQuery<{ loreStories: LoreStory[] }>(LORE_STORIES_QUERY);
  const { data: outpostData } = useQuery<{ outposts: OutpostNode[] }>(OUTPOSTS_QUERY);
  const { data: laneData } = useQuery<{ raidLanes: RaidLane[] }>(RAID_LANES_QUERY);

  if (loading) return <p className="apollo-status">Querying docs/content graph…</p>;
  if (error) return <p className="apollo-status apollo-error">{error.message}</p>;

  return (
    <>
      <div className="apollo-stats">
        <div className="apollo-stat">
          <span className="apollo-stat-value">{outpostData?.outposts.length ?? "—"}</span>
          <span className="apollo-stat-label">Outposts</span>
        </div>
        <div className="apollo-stat">
          <span className="apollo-stat-value">{laneData?.raidLanes.length ?? "—"}</span>
          <span className="apollo-stat-label">Raid lanes</span>
        </div>
        <div className="apollo-stat">
          <span className="apollo-stat-value">{data?.loreStories.length ?? 0}</span>
          <span className="apollo-stat-label">Lore stories</span>
        </div>
      </div>

      <ul className="apollo-lore-list">
        {data?.loreStories.map((story) => (
          <li key={story.id} className="apollo-lore-card">
            <div className="apollo-lore-header">
              <h3>{story.title}</h3>
              <span className="apollo-lore-era">{story.era}</span>
            </div>
            <p>{story.summary}</p>
            <div className="apollo-lore-footer">
              <div className="apollo-lore-tags">
                {story.tags.map((tag) => (
                  <span key={tag} className="apollo-tag">
                    {tag}
                  </span>
                ))}
              </div>
              {story.docPath && (
                <a className="apollo-lore-link" href={story.docPath}>
                  Read more →
                </a>
              )}
            </div>
          </li>
        ))}
      </ul>
    </>
  );
}

/**
 * Framework island · Apollo/GraphQL — queries src/graphql/schema.graphql's
 * real Query fields (outposts, raidLanes, loreStories), served from this
 * repo's own lore/outpost data (see ./client.ts) since there's no live docs
 * backend yet.
 */
export default function ApolloLorePanel() {
  return (
    <ApolloProvider client={apolloClient}>
      <section className="apollo-island-wrap panel">
        <p className="island-label">Framework island · Apollo/GraphQL — docs/content graph (src/graphql/)</p>
        <LoreStoriesGrid />
      </section>
    </ApolloProvider>
  );
}

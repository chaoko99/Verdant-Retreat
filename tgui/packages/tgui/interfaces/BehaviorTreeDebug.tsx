import { useBackend } from '../backend';
import { Box, Section, Stack, LabeledList, Button, Collapsible } from 'tgui-core/components';
import { Window } from '../layouts';
import { useState } from 'react';

type NodeData = {
  type: string;
  name: string;
  state: number;
  children: NodeData[];
  diagnostics?: Record<string, any>;
};

type AIState = {
  has_target: boolean;
  target_name: string;
  target_stat: string;
  has_move_destination: boolean;
  move_destination: string;
  destination_same_as_target: boolean;
  path_length: number;
  has_running_node: boolean;
  running_node_type: string;
  active_node_text: string;
  next_think_tick: number;
  next_move_tick: number;
  world_time: number;
  can_think: boolean;
  can_move: boolean;
  distance_to_target?: number;
  adjacent_to_target?: boolean;
};

type Data = {
  has_ai: boolean;
  selecting: boolean;
  mob_name: string;
  blackboard: Array<{key: string; value: string}>;
  tree: NodeData;
  ai_state: AIState | null;
  selected_count: number;
  selected_mobs: string[];
  spawn_categories: Record<string, Record<string, string>>;
  unit_tests: string[];
};

const NODE_FAILURE = 0;
const NODE_SUCCESS = 1;
const NODE_RUNNING = 2;

const NodeView = (props: { node: NodeData | null; selectedNode: NodeData | null; onNodeClick: (node: NodeData) => void }) => {
  const { node, selectedNode, onNodeClick } = props;

  if (!node) {
    return null;
  }

  let color = 'grey';
  if (node.state === NODE_SUCCESS) color = 'green';
  else if (node.state === NODE_FAILURE) color = 'red';
  else if (node.state === NODE_RUNNING) color = 'blue';

  const isSelected = selectedNode === node;

  return (
    <Box mb={1}>
      <Box
        p={1}
        backgroundColor={color}
        textColor="white"
        style={{
          border: isSelected ? '2px solid yellow' : '1px solid black',
          borderRadius: '3px',
          cursor: 'pointer'
        }}
        onClick={() => onNodeClick(node)}
      >
        <Stack>
          <Stack.Item grow>
            {node.name}
          </Stack.Item>
          <Stack.Item>
            <Box fontSize="0.8em" opacity={0.8}>
              {node.type}
            </Box>
          </Stack.Item>
        </Stack>
      </Box>

      {node.children && node.children.length > 0 && (
        <Box ml={2} mt={0.5} pl={1} style={{ borderLeft: '1px solid rgba(255,255,255,0.2)' }}>
          {node.children.map((child, i) => (
            child && <NodeView key={i} node={child} selectedNode={selectedNode} onNodeClick={onNodeClick} />
          ))}
        </Box>
      )}
    </Box>
  );
};

const MobSpawner = (props) => {
  const { act, data } = useBackend<Data>(props);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set());

  const toggleCategory = (category: string) => {
    const newExpanded = new Set(expandedCategories);
    if (newExpanded.has(category)) {
      newExpanded.delete(category);
    } else {
      newExpanded.add(category);
    }
    setExpandedCategories(newExpanded);
  };

  return (
    <Section title="Spawn Mobs">
      {Object.keys(data.spawn_categories || {}).map(category => (
        <Collapsible
          key={category}
          title={category}
          open={expandedCategories.has(category)}
          onClick={() => toggleCategory(category)}
        >
          <Stack vertical>
            {Object.keys(data.spawn_categories[category]).map(mobName => (
              <Stack.Item key={mobName}>
                <Button
                  fluid
                  onClick={() => {
                    console.log('Button clicked for:', mobName);
                    act('spawn_mob', { path: data.spawn_categories[category][mobName] });
                  }}
                >
                  {mobName}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Collapsible>
      ))}
      <Box mt={1} color="label" fontSize="0.9em">
        Hint: Mobs spawn at your location
      </Box>
    </Section>
  );
};

const UnitTestPanel = (props) => {
  const { act, data } = useBackend<Data>(props);

  return (
    <Section title="Unit Tests">
      <Stack vertical>
        {(data.unit_tests || []).map(testName => (
          <Stack.Item key={testName}>
            <Button
              fluid
              icon="vial"
              color="average"
              onClick={() => act('run_unit_test', { test_name: testName })}
            >
              {testName}
            </Button>
          </Stack.Item>
        ))}
      </Stack>
      <Box mt={1} color="label" fontSize="0.9em">
        Results appear in chat. Tests spawn mobs at your location.
      </Box>
    </Section>
  );
};

const SelectionPanel = (props) => {
  const { act, data } = useBackend<Data>(props);

  return (
    <Section title={`Selected Mobs (${data.selected_count || 0})`}>
      <Stack vertical>
        <Stack.Item>
          <Button
            fluid
            color="good"
            icon="mouse-pointer"
            onClick={() => act('start_selecting')}
          >
            Select Mob to Debug
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            color="bad"
            disabled={!data.selected_count}
            onClick={() => act('delete_selected')}
          >
            Delete Selected
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            disabled={!data.selected_count}
            onClick={() => act('clear_selection')}
          >
            Clear Selection
          </Button>
        </Stack.Item>
        {data.selected_mobs && data.selected_mobs.length > 0 && (
          <Stack.Item>
            <Box
              p={1}
              backgroundColor="rgba(255,255,255,0.05)"
              style={{ maxHeight: '150px', overflowY: 'auto', fontSize: '0.9em' }}
            >
              {data.selected_mobs.map((mobName, i) => (
                <Box key={i}>{mobName}</Box>
              ))}
            </Box>
          </Stack.Item>
        )}
      </Stack>
      <Box mt={1} color="label" fontSize="0.9em">
        Hint: Ctrl+Click to multi-select | Shift+Drag for box select
      </Box>
    </Section>
  );
};

const AIStatePanel = (props: { aiState: AIState | null }) => {
  const { aiState } = props;

  if (!aiState) {
    return null;
  }

  return (
    <Section title="AI State">
      <LabeledList>
        <LabeledList.Item label="Target" color={aiState.has_target ? 'good' : 'bad'}>
          {aiState.has_target ? `${aiState.target_name} (stat: ${aiState.target_stat})` : 'None'}
        </LabeledList.Item>
        {aiState.has_target && (
          <>
            <LabeledList.Item label="Distance">
              {aiState.distance_to_target !== undefined ? aiState.distance_to_target : 'N/A'}
            </LabeledList.Item>
            <LabeledList.Item label="Adjacent" color={aiState.adjacent_to_target ? 'good' : 'average'}>
              {aiState.adjacent_to_target ? 'Yes' : 'No'}
            </LabeledList.Item>
          </>
        )}
        <LabeledList.Item label="Move Destination" color={aiState.has_move_destination ? 'average' : 'label'}>
          {aiState.has_move_destination ? aiState.move_destination : 'None'}
        </LabeledList.Item>
        {aiState.has_move_destination && (
          <LabeledList.Item label="Dest = Target?" color={aiState.destination_same_as_target ? 'good' : 'bad'}>
            {aiState.destination_same_as_target ? 'Yes' : 'No'}
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Path Length">
          {aiState.path_length}
        </LabeledList.Item>
        <LabeledList.Item label="Running Node" color={aiState.has_running_node ? 'average' : 'label'}>
          {aiState.has_running_node ? aiState.running_node_type : 'None'}
        </LabeledList.Item>
        <LabeledList.Item label="Active Action">
          {aiState.active_node_text || 'None'}
        </LabeledList.Item>
        <LabeledList.Item label="Can Think" color={aiState.can_think ? 'good' : 'bad'}>
          {aiState.can_think ? 'Yes' : `No (${aiState.next_think_tick - aiState.world_time} ticks)`}
        </LabeledList.Item>
        <LabeledList.Item label="Can Move" color={aiState.can_move ? 'good' : 'bad'}>
          {aiState.can_move ? 'Yes' : `No (${aiState.next_move_tick - aiState.world_time} ticks)`}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const NodeDiagnostics = (props: { node: NodeData | null }) => {
  const { node } = props;

  if (!node || !node.diagnostics || Object.keys(node.diagnostics).length === 0) {
    return (
      <Section title="Node Diagnostics">
        <Box p={2} textAlign="center" color="label">
          Click on a node in the tree to see diagnostics
        </Box>
      </Section>
    );
  }

  return (
    <Section title={`Diagnostics: ${node.name}`}>
      <LabeledList>
        {Object.entries(node.diagnostics).map(([key, value]) => {
          let displayValue = value;
          let color = undefined;

          // Format boolean values with colors
          if (typeof value === 'boolean') {
            displayValue = value ? 'Yes' : 'No';
            // Color based on what makes sense for the key
            if (key.includes('has_') || key.includes('can_') || key.includes('in_range') || key.includes('alive')) {
              color = value ? 'good' : 'bad';
            } else if (key.includes('adjacent')) {
              color = value ? 'good' : 'average';
            }
          } else if (Array.isArray(value)) {
            displayValue = value.join(', ');
          } else if (typeof value === 'object') {
            displayValue = JSON.stringify(value);
          } else {
            displayValue = String(value);
          }

          return (
            <LabeledList.Item key={key} label={key} color={color}>
              {displayValue}
            </LabeledList.Item>
          );
        })}
      </LabeledList>
    </Section>
  );
};

export const BehaviorTreeDebug = (props) => {
  const { data } = useBackend<Data>(props);
  const [selectedNode, setSelectedNode] = useState<NodeData | null>(null);

  const title = data.has_ai ? `BT Debug: ${data.mob_name}` : "Behavior Tree Debugger";

  return (
    <Window title={title} width={1200} height={900}>
      <Window.Content scrollable>
        <Stack>
          <Stack.Item basis="50%">
            <Stack vertical>
              {data.has_ai ? (
                <>
                  <Stack.Item>
                    <AIStatePanel aiState={data.ai_state} />
                  </Stack.Item>

                  <Stack.Item>
                    <Section title="Tree Structure">
                      {data.tree && <NodeView node={data.tree} selectedNode={selectedNode} onNodeClick={setSelectedNode} />}
                    </Section>
                  </Stack.Item>
                </>
              ) : (
                <Stack.Item>
                  <Section title="No Mob Selected">
                    <Box p={2} textAlign="center">
                      <Box fontSize="1.1em" mb={1} color="label">
                        Click "Select Mob to Debug" to choose a mob
                      </Box>
                      <Box fontSize="0.9em" color="label">
                        Or spawn mobs using the panel on the right
                      </Box>
                    </Box>
                  </Section>
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>

          <Stack.Item basis="50%">
            <Stack vertical>
              {data.has_ai && (
                <Stack.Item>
                  <NodeDiagnostics node={selectedNode} />
                </Stack.Item>
              )}
              <Stack.Item>
                <SelectionPanel {...props} />
              </Stack.Item>
              <Stack.Item>
                <UnitTestPanel {...props} />
              </Stack.Item>
              <Stack.Item>
                <MobSpawner {...props} />
              </Stack.Item>
              {data.has_ai && (
                <Stack.Item>
                  <Section title="Blackboard">
                    <Box style={{ maxHeight: '200px', overflowY: 'auto' }}>
                      <LabeledList>
                        {(data.blackboard || []).length > 0 ? (
                          data.blackboard.map((entry, i) => (
                            <LabeledList.Item key={i} label={entry.key}>
                              {entry.value}
                            </LabeledList.Item>
                          ))
                        ) : (
                          <Box color="label">Empty</Box>
                        )}
                      </LabeledList>
                    </Box>
                  </Section>
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

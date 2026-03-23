import React, { useEffect, useState } from 'react';
import {
  Content,
  ContentHeader,
  Header,
  Page,
  Progress,
  ResponseErrorPanel,
  InfoCard,
} from '@backstage/core-components';
import {
  useApi,
  identityApiRef,
} from '@backstage/core-plugin-api';
import {
  Box,
  Chip,
  Grid,
  LinearProgress,
  Tooltip,
  Typography,
  makeStyles,
} from '@material-ui/core';
import CheckCircleOutlineIcon from '@material-ui/icons/CheckCircleOutline';
import ErrorOutlineIcon from '@material-ui/icons/ErrorOutline';
import HourglassEmptyIcon from '@material-ui/icons/HourglassEmpty';
import { dojoProgressApiRef, BeltProgress, LabResult } from '../../api';

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

const useStyles = makeStyles(theme => ({
  beltCard: {
    marginBottom: theme.spacing(2),
  },
  beltHeader: {
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(1),
    marginBottom: theme.spacing(1),
  },
  beltIcon: {
    fontSize: '1.5rem',
  },
  beltName: {
    textTransform: 'capitalize',
    fontWeight: 600,
  },
  completionBar: {
    height: 10,
    borderRadius: 5,
    marginBottom: theme.spacing(1),
  },
  pctLabel: {
    fontSize: '0.8rem',
    color: theme.palette.text.secondary,
    marginBottom: theme.spacing(1),
  },
  labGrid: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: theme.spacing(0.5),
  },
  labChipPass: {
    backgroundColor: theme.palette.success.main,
    color: theme.palette.success.contrastText,
  },
  labChipFail: {
    backgroundColor: theme.palette.error.main,
    color: theme.palette.error.contrastText,
  },
  labChipPending: {
    backgroundColor: theme.palette.action.disabledBackground,
  },
  emptyState: {
    textAlign: 'center',
    padding: theme.spacing(4),
    color: theme.palette.text.secondary,
  },
}));

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

const LabStatusIcon: React.FC<{ status: LabResult['status'] }> = ({
  status,
}) => {
  if (status === 'PASS')
    return <CheckCircleOutlineIcon fontSize="small" color="inherit" />;
  if (status === 'FAIL')
    return <ErrorOutlineIcon fontSize="small" color="inherit" />;
  return <HourglassEmptyIcon fontSize="small" color="inherit" />;
};

const BeltRow: React.FC<{ progress: BeltProgress }> = ({ progress }) => {
  const classes = useStyles();
  const { belt, icon, colour, completionPct, labs } = progress;

  return (
    <InfoCard className={classes.beltCard}>
      <Box className={classes.beltHeader}>
        <span className={classes.beltIcon}>{icon}</span>
        <Typography variant="h6" className={classes.beltName}>
          {belt} belt
        </Typography>
        <Chip
          size="small"
          label={`${completionPct}%`}
          style={{ backgroundColor: colour, marginLeft: 'auto' }}
        />
      </Box>

      <LinearProgress
        variant="determinate"
        value={completionPct}
        className={classes.completionBar}
        color={completionPct === 100 ? 'primary' : 'secondary'}
      />

      <Typography className={classes.pctLabel}>
        {labs.filter(l => l.status === 'PASS').length} / {labs.length} labs
        completed
      </Typography>

      {labs.length === 0 ? (
        <Typography variant="body2" color="textSecondary">
          No labs recorded yet. Complete a lab and run its{' '}
          <code>validate.sh</code> to see results here.
        </Typography>
      ) : (
        <Box className={classes.labGrid}>
          {labs.map(lab => (
            <Tooltip key={lab.id} title={`${lab.label}: ${lab.status}`}>
              <Chip
                size="small"
                label={lab.label}
                icon={<LabStatusIcon status={lab.status} />}
                className={
                  lab.status === 'PASS'
                    ? classes.labChipPass
                    : lab.status === 'FAIL'
                    ? classes.labChipFail
                    : classes.labChipPending
                }
              />
            </Tooltip>
          ))}
        </Box>
      )}
    </InfoCard>
  );
};

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

/**
 * DojoProgressPage — renders a dashboard showing a learner's belt progress.
 *
 * Data is fetched from the `fawkes-dojo-progress` Kubernetes ConfigMap via
 * the Backstage proxy endpoint `/dojo/progress`.
 *
 * To integrate into the Backstage app:
 * 1. Add a route: <Route path="/dojo" element={<DojoProgressPage />} />
 * 2. Add a sidebar item:
 *    <SidebarItem icon={SchoolIcon} to="dojo" text="Dojo" />
 */
export const DojoProgressPage: React.FC = () => {
  const classes = useStyles();
  const dojoApi = useApi(dojoProgressApiRef);
  const identityApi = useApi(identityApiRef);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [username, setUsername] = useState<string>('');
  const [belts, setBelts] = useState<BeltProgress[] | null>(null);

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const identity = await identityApi.getBackstageIdentity();
        // Extract the GitHub username from the entity ref (user:default/alice → alice)
        const user =
          identity.userEntityRef.split('/').pop() ?? 'unknown';

        if (cancelled) return;
        setUsername(user);

        const progress = await dojoApi.getProgress(user);

        if (cancelled) return;
        setBelts(progress?.belts ?? null);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err : new Error(String(err)));
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    load();
    return () => {
      cancelled = true;
    };
  }, [dojoApi, identityApi]);

  return (
    <Page themeId="tool">
      <Header
        title="Dojo Progress"
        subtitle="Your Fawkes belt progression dashboard"
      />
      <Content>
        <ContentHeader title={username ? `Progress for @${username}` : ''} />

        {loading && <Progress />}

        {!loading && error && <ResponseErrorPanel error={error} />}

        {!loading && !error && belts === null && (
          <Box className={classes.emptyState}>
            <Typography variant="h6">No progress recorded yet</Typography>
            <Typography variant="body2">
              Complete a dojo lab and run its <code>validate.sh</code> script.
              Your results will appear here automatically.
            </Typography>
          </Box>
        )}

        {!loading && !error && belts !== null && (
          <Grid container spacing={2}>
            <Grid item xs={12} md={8}>
              {belts.map(b => (
                <BeltRow key={b.belt} progress={b} />
              ))}
            </Grid>
          </Grid>
        )}
      </Content>
    </Page>
  );
};

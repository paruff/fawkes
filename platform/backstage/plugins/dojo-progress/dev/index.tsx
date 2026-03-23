import React from 'react';
import { createDevApp } from '@backstage/dev-utils';
import { dojoProgressPlugin, DojoProgressPage } from '../src';
import { dojoProgressApiRef } from '../src/api';
import type { DojoProgressApi } from '../src/api';

/** Stub API that returns sample data for local development. */
const mockDojoProgressApi: DojoProgressApi = {
  async getProgress(username: string) {
    return {
      username,
      lastUpdated: new Date().toISOString(),
      belts: [
        {
          belt: 'white',
          colour: '#f5f5f5',
          icon: '🥋',
          completionPct: 75,
          labs: [
            { id: 'lab-01', label: 'Lab 01', status: 'PASS' },
            { id: 'lab-02', label: 'Lab 02', status: 'PASS' },
            { id: 'lab-03', label: 'Lab 03', status: 'PASS' },
            { id: 'lab-04', label: 'Lab 04', status: 'FAIL' },
          ],
        },
        {
          belt: 'yellow',
          colour: '#fdd835',
          icon: '🟡',
          completionPct: 25,
          labs: [
            { id: 'lab-05', label: 'Lab 05', status: 'PASS' },
            { id: 'lab-06', label: 'Lab 06', status: 'PENDING' },
            { id: 'lab-07', label: 'Lab 07', status: 'PENDING' },
            { id: 'lab-08', label: 'Lab 08', status: 'PENDING' },
          ],
        },
        {
          belt: 'green',
          colour: '#43a047',
          icon: '🟢',
          completionPct: 0,
          labs: [],
        },
        {
          belt: 'brown',
          colour: '#6d4c41',
          icon: '🟤',
          completionPct: 0,
          labs: [],
        },
        {
          belt: 'black',
          colour: '#212121',
          icon: '⚫',
          completionPct: 0,
          labs: [],
        },
      ],
    };
  },
};

createDevApp()
  .registerPlugin(dojoProgressPlugin)
  .addPage({
    element: <DojoProgressPage />,
    title: 'Dojo Progress',
    path: '/dojo',
  })
  .registerApi({
    api: dojoProgressApiRef,
    deps: {},
    factory: () => mockDojoProgressApi,
  })
  .render();
